;; Innovation Accelerator Contract
;; A decentralized platform for funding and accelerating innovation projects
;; with milestone-based progress tracking and mentor rewards

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-PROJECT-NOT-FOUND (err u404))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-PROJECT-CLOSED (err u403))
(define-constant ERR-MILESTONE-NOT-FOUND (err u405))
(define-constant ERR-ALREADY-FUNDED (err u406))
(define-constant ERR-MILESTONE-COMPLETED (err u407))
(define-constant ERR-INVALID-STATUS (err u408))
(define-constant ERR-DEADLINE-PASSED (err u409))
(define-constant ERR-NOT-MENTOR (err u410))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Project statuses
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-CANCELLED u3)
(define-constant STATUS-FUNDED u4)

;; Milestone statuses
(define-constant MILESTONE-PENDING u1)
(define-constant MILESTONE-COMPLETED u2)
(define-constant MILESTONE-FAILED u3)

;; Platform configuration
(define-data-var project-nonce uint u0)
(define-data-var milestone-nonce uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee
(define-data-var min-funding-goal uint u1000) ;; Minimum funding in microSTX
(define-data-var total-platform-funds uint u0)

;; Data Maps

;; Innovation projects registry
(define-map projects
  { project-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    funding-goal: uint,
    current-funding: uint,
    created-at: uint,
    deadline: uint,
    status: uint,
    mentor: (optional principal),
    mentor-fee: uint,
    milestone-count: uint,
    completed-milestones: uint
  }
)

;; Project milestones
(define-map milestones
  { project-id: uint, milestone-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    funding-amount: uint,
    deadline: uint,
    status: uint,
    completed-at: (optional uint),
    reviewer: (optional principal)
  }
)

;; Project funding by backers
(define-map project-funding
  { project-id: uint, backer: principal }
  {
    amount: uint,
    funded-at: uint,
    rewards-claimed: bool
  }
)

;; Mentor assignments and earnings
(define-map mentor-profiles
  { mentor: principal }
  {
    projects-mentored: uint,
    total-earned: uint,
    success-rate: uint,
    specialization: (string-ascii 100),
    joined-at: uint
  }
)

;; Project reviews and ratings
(define-map project-reviews
  { project-id: uint, reviewer: principal }
  {
    rating: uint, ;; 1-5 stars
    comment: (string-ascii 200),
    reviewed-at: uint
  }
)

;; Public Functions

;; Create a new innovation project
(define-public (create-project 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (funding-goal uint)
  (deadline-blocks uint)
  (mentor-fee uint)
)
  (let
    (
      (project-id (+ (var-get project-nonce) u1))
      (creator tx-sender)
    )
    (asserts! (>= funding-goal (var-get min-funding-goal)) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> deadline-blocks burn-block-height) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u10) ERR-INVALID-INPUT)
    (asserts! (<= mentor-fee (/ funding-goal u10)) ERR-INVALID-INPUT) ;; Max 10% mentor fee
    
    ;; Create project
    (map-set projects
      {project-id: project-id}
      {
        creator: creator,
        title: title,
        description: description,
        category: category,
        funding-goal: funding-goal,
        current-funding: u0,
        created-at: burn-block-height,
        deadline: deadline-blocks,
        status: STATUS-ACTIVE,
        mentor: none,
        mentor-fee: mentor-fee,
        milestone-count: u0,
        completed-milestones: u0
      }
    )
    
    (var-set project-nonce project-id)
    (ok project-id)
  )
)

;; Add milestone to a project
(define-public (add-milestone
  (project-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (funding-amount uint)
  (milestone-deadline uint)
)
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
      (milestone-id (+ (get milestone-count project) u1))
    )
    (asserts! (is-eq tx-sender (get creator project)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-INVALID-STATUS)
    (asserts! (> milestone-deadline burn-block-height) ERR-INVALID-INPUT)
    (asserts! (> funding-amount u0) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    
    ;; Add milestone
    (map-set milestones
      {project-id: project-id, milestone-id: milestone-id}
      {
        title: title,
        description: description,
        funding-amount: funding-amount,
        deadline: milestone-deadline,
        status: MILESTONE-PENDING,
        completed-at: none,
        reviewer: none
      }
    )
    
    ;; Update project milestone count
    (map-set projects
      {project-id: project-id}
      (merge project {milestone-count: milestone-id})
    )
    
    (ok milestone-id)
  )
)

;; Fund a project
(define-public (fund-project (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
      (backer tx-sender)
      (existing-funding (default-to u0 (get amount (map-get? project-funding {project-id: project-id, backer: backer}))))
    )
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-PROJECT-CLOSED)
    (asserts! (< burn-block-height (get deadline project)) ERR-DEADLINE-PASSED)
    (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
    
    ;; Transfer funds to contract
    (try! (stx-transfer? amount backer (as-contract tx-sender)))
    
    ;; Record funding
    (map-set project-funding
      {project-id: project-id, backer: backer}
      {
        amount: (+ existing-funding amount),
        funded-at: burn-block-height,
        rewards-claimed: false
      }
    )
    
    ;; Update project funding
    (let ((new-funding (+ (get current-funding project) amount)))
      (map-set projects
        {project-id: project-id}
        (merge project {
          current-funding: new-funding,
          status: (if (>= new-funding (get funding-goal project)) STATUS-FUNDED STATUS-ACTIVE)
        })
      )
    )
    
    (var-set total-platform-funds (+ (var-get total-platform-funds) amount))
    (ok true)
  )
)

;; Assign mentor to project
(define-public (assign-mentor (project-id uint) (mentor principal))
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get creator project)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (get mentor project)) ERR-ALREADY-FUNDED)
    (asserts! (is-eq (get status project) STATUS-ACTIVE) ERR-INVALID-STATUS)
    
    ;; Update project with mentor
    (map-set projects
      {project-id: project-id}
      (merge project {mentor: (some mentor)})
    )
    
    ;; Initialize or update mentor profile
    (let
      (
        (mentor-profile (default-to 
          {projects-mentored: u0, total-earned: u0, success-rate: u100, specialization: "", joined-at: burn-block-height}
          (map-get? mentor-profiles {mentor: mentor})
        ))
      )
      (map-set mentor-profiles
        {mentor: mentor}
        (merge mentor-profile {
          projects-mentored: (+ (get projects-mentored mentor-profile) u1),
          joined-at: (if (is-eq (get projects-mentored mentor-profile) u0) burn-block-height (get joined-at mentor-profile))
        })
      )
    )
    
    (ok true)
  )
)

;; Complete a milestone
(define-public (complete-milestone (project-id uint) (milestone-id uint))
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
      (milestone (unwrap! (map-get? milestones {project-id: project-id, milestone-id: milestone-id}) ERR-MILESTONE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get creator project)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status milestone) MILESTONE-PENDING) ERR-MILESTONE-COMPLETED)
    (asserts! (is-eq (get status project) STATUS-FUNDED) ERR-INVALID-STATUS)
    
    ;; Mark milestone as completed
    (map-set milestones
      {project-id: project-id, milestone-id: milestone-id}
      (merge milestone {
        status: MILESTONE-COMPLETED,
        completed-at: (some burn-block-height),
        reviewer: (get mentor project)
      })
    )
    
    ;; Update project completed milestones
    (let ((new-completed (+ (get completed-milestones project) u1)))
      (map-set projects
        {project-id: project-id}
        (merge project {
          completed-milestones: new-completed,
          status: (if (is-eq new-completed (get milestone-count project)) STATUS-COMPLETED STATUS-FUNDED)
        })
      )
    )
    
    ;; Release milestone funding to creator
    (let
      (
        (milestone-amount (get funding-amount milestone))
        (platform-fee (/ (* milestone-amount (var-get platform-fee-percentage)) u100))
        (creator-amount (- milestone-amount platform-fee))
      )
      (try! (as-contract (stx-transfer? creator-amount tx-sender (get creator project))))
      (var-set total-platform-funds (- (var-get total-platform-funds) milestone-amount))
    )
    
    (ok true)
  )
)

;; Claim mentor rewards when project completes
(define-public (claim-mentor-rewards (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
      (mentor-address (unwrap! (get mentor project) ERR-NOT-MENTOR))
    )
    (asserts! (is-eq tx-sender mentor-address) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status project) STATUS-COMPLETED) ERR-INVALID-STATUS)
    
    ;; Transfer mentor fee
    (let
      (
        (mentor-fee (get mentor-fee project))
        (mentor-profile (unwrap! (map-get? mentor-profiles {mentor: mentor-address}) ERR-NOT-MENTOR))
      )
      (try! (as-contract (stx-transfer? mentor-fee tx-sender mentor-address)))
      
      ;; Update mentor earnings
      (map-set mentor-profiles
        {mentor: mentor-address}
        (merge mentor-profile {
          total-earned: (+ (get total-earned mentor-profile) mentor-fee)
        })
      )
    )
    
    (ok true)
  )
)

;; Submit project review
(define-public (submit-review
  (project-id uint)
  (rating uint)
  (comment (string-ascii 200))
)
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
      (reviewer tx-sender)
    )
    (asserts! (>= rating u1) ERR-INVALID-INPUT)
    (asserts! (<= rating u5) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status project) STATUS-COMPLETED) ERR-INVALID-STATUS)
    (asserts! (is-some (map-get? project-funding {project-id: project-id, backer: reviewer})) ERR-NOT-AUTHORIZED)
    
    ;; Submit review
    (map-set project-reviews
      {project-id: project-id, reviewer: reviewer}
      {
        rating: rating,
        comment: comment,
        reviewed-at: burn-block-height
      }
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects {project-id: project-id})
)

;; Get milestone details
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? milestones {project-id: project-id, milestone-id: milestone-id})
)

;; Get project funding by backer
(define-read-only (get-project-funding (project-id uint) (backer principal))
  (map-get? project-funding {project-id: project-id, backer: backer})
)

;; Get mentor profile
(define-read-only (get-mentor-profile (mentor principal))
  (map-get? mentor-profiles {mentor: mentor})
)

;; Get project review
(define-read-only (get-project-review (project-id uint) (reviewer principal))
  (map-get? project-reviews {project-id: project-id, reviewer: reviewer})
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-projects: (var-get project-nonce),
    total-milestones: (var-get milestone-nonce),
    platform-funds: (var-get total-platform-funds),
    min-funding-goal: (var-get min-funding-goal),
    platform-fee-percentage: (var-get platform-fee-percentage)
  }
)

;; Administrative functions (contract owner only)

;; Update platform fee
(define-public (set-platform-fee (fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= fee-percentage u20) ERR-INVALID-INPUT) ;; Max 20% fee
    (var-set platform-fee-percentage fee-percentage)
    (ok true)
  )
)

;; Update minimum funding goal
(define-public (set-min-funding-goal (min-goal uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> min-goal u0) ERR-INVALID-INPUT)
    (var-set min-funding-goal min-goal)
    (ok true)
  )
)

;; Emergency function to cancel a project (admin only)
(define-public (cancel-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects {project-id: project-id}) ERR-PROJECT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status project) STATUS-COMPLETED)) ERR-INVALID-STATUS)
    
    ;; Update project status
    (map-set projects
      {project-id: project-id}
      (merge project {status: STATUS-CANCELLED})
    )
    
    (ok true)
  )
)

;; Initialize contract
(begin
  (var-set platform-fee-percentage u5)
  (var-set min-funding-goal u1000)
  (var-set total-platform-funds u0)
)