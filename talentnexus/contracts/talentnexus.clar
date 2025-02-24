;; TalentNexus - Decentralized Professional Marketplace
;; Smart contract for managing professional services, payments, and platform features

(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-PROJECT (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-PROJECT-INACTIVE (err u4))
(define-constant ERR-STAGE-MISMATCH (err u5))
(define-constant ERR-DEPOSIT-LOCKED (err u6))
(define-constant ERR-INVALID-PAYMENT (err u7))
(define-constant ERR-MAX-MILESTONES (err u8))
(define-constant ERR-INVALID-TALENT (err u9))
(define-constant ERR-INVALID-DESCRIPTION (err u10))
(define-constant ERR-INVALID-CATEGORY (err u11))
(define-constant ERR-INVALID-DURATION (err u12))
(define-constant ERR-INVALID-NAME (err u13))
(define-constant ERR-INVALID-PROJECT-ID (err u14))
(define-constant ERR-INVALID-MILESTONE-ID (err u15))
(define-constant ERR-INVALID-EVIDENCE (err u16))
(define-constant DEPOSIT-LOCK-TIME u1440)
(define-constant SERVICE-FEE u25)
(define-constant MIN-DEPOSIT u1000000)
(define-constant MAX-MILESTONES u10)
(define-constant MAX-DURATION u14400)

;; Data Structures
(define-map Projects
    { project-id: uint }
    {
        client: principal,
        talent: principal,
        total-budget: uint,
        remaining-budget: uint,
        description: (string-ascii 256),
        category: (string-ascii 64),
        status: (string-ascii 20),
        start-time: uint,
        completion-time: uint,
        deadline: uint,
        arbitrator: (optional principal),
        total-milestones: uint,
        completed-milestones: uint
    }
)

(define-map Milestones
    { project-id: uint, milestone-id: uint }
    {
        description: (string-ascii 256),
        payment: uint,
        status: (string-ascii 20),
        deadline: uint
    }
)

(define-map TalentRatings
    { professional: principal }
    {
        total-reviews: uint,
        rating-sum: uint,
        completed-projects: uint,
        disputes-won: uint,
        disputes-lost: uint
    }
)

(define-map TalentDeposits
    { professional: principal }
    {
        deposit: uint,
        lock-expiry: uint
    }
)

(define-map Categories
    { category-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        min-deposit: uint
    }
)

(define-map DisputeEvidence
    { project-id: uint, party: principal }
    {
        evidence-hash: (buff 32),
        submit-time: uint
    }
)

(define-data-var project-counter uint u0)
(define-data-var category-counter uint u0)

;; Validation helpers
(define-private (is-valid-talent (talent principal))
    (is-some (map-get? TalentDeposits { professional: talent })))

(define-private (is-valid-description (description (string-ascii 256)))
    (and 
        (not (is-eq description ""))
        (<= (len description) u256)))

(define-private (is-valid-category (category (string-ascii 64)))
    (and 
        (not (is-eq category ""))
        (<= (len category) u64)))

(define-private (is-valid-duration (duration uint))
    (and 
        (> duration u0)
        (<= duration MAX-DURATION)))

(define-private (is-valid-name (name (string-ascii 64)))
    (and 
        (not (is-eq name ""))
        (<= (len name) u64)))

(define-private (is-valid-project-id (project-id uint))
    (and
        (> project-id u0)
        (<= project-id (var-get project-counter))))

(define-private (is-valid-milestone-id (project-id uint) (milestone-id uint))
    (match (map-get? Projects { project-id: project-id })
        project (< milestone-id (get total-milestones project))
        false))

(define-private (is-valid-payment (payment uint))
    (> payment u0))

(define-private (is-valid-evidence-hash (evidence-hash (buff 32)))
    (not (is-eq evidence-hash 0x0000000000000000000000000000000000000000000000000000000000000000)))

;; Deposit management
(define-public (make-deposit (amount uint))
    (begin
        (asserts! (>= amount MIN-DEPOSIT) ERR-INVALID-PAYMENT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set TalentDeposits
            { professional: tx-sender }
            {
                deposit: amount,
                lock-expiry: (+ block-height DEPOSIT-LOCK-TIME)
            }
        )
        (ok true)))

(define-public (withdraw-deposit)
    (let ((deposit-info (unwrap! (map-get? TalentDeposits { professional: tx-sender }) ERR-NOT-AUTHORIZED)))
        (asserts! (>= block-height (get lock-expiry deposit-info)) ERR-DEPOSIT-LOCKED)
        (try! (as-contract (stx-transfer? (get deposit deposit-info) tx-sender tx-sender)))
        (map-delete TalentDeposits { professional: tx-sender })
        (ok true)))

;; Project creation
(define-public (create-project 
    (talent principal) 
    (total-budget uint) 
    (description (string-ascii 256))
    (category (string-ascii 64))
    (duration uint))
    
    (begin
        (asserts! (is-valid-talent talent) ERR-INVALID-TALENT)
        (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
        (asserts! (is-valid-category category) ERR-INVALID-CATEGORY)
        (asserts! (is-valid-duration duration) ERR-INVALID-DURATION)
        (asserts! (is-valid-payment total-budget) ERR-INVALID-PAYMENT)
        
        (let ((project-id (+ (var-get project-counter) u1))
              (platform-fee (/ (* total-budget SERVICE-FEE) u1000)))
            
            (asserts! (>= (stx-get-balance tx-sender) (+ total-budget platform-fee)) 
                     ERR-INSUFFICIENT-FUNDS)
            
            (try! (stx-transfer? (+ total-budget platform-fee) 
                                tx-sender 
                                (as-contract tx-sender)))
            
            (map-set Projects
                { project-id: project-id }
                {
                    client: tx-sender,
                    talent: talent,
                    total-budget: total-budget,
                    remaining-budget: total-budget,
                    description: description,
                    category: category,
                    status: "active",
                    start-time: block-height,
                    completion-time: u0,
                    deadline: (+ block-height duration),
                    arbitrator: none,
                    total-milestones: u0,
                    completed-milestones: u0
                }
            )
            
            (var-set project-counter project-id)
            (ok project-id))))

;; Add milestone
(define-public (add-milestone 
    (project-id uint)
    (description (string-ascii 256))
    (payment uint))
    
    (begin
        (asserts! (is-valid-project-id project-id) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
        (asserts! (is-valid-payment payment) ERR-INVALID-PAYMENT)
        
        (let ((project (unwrap! (map-get? Projects { project-id: project-id }) ERR-INVALID-PROJECT)))
            (asserts! (is-eq tx-sender (get client project)) ERR-NOT-AUTHORIZED)
            (asserts! (is-eq (get status project) "active") ERR-PROJECT-INACTIVE)
            (asserts! (< (get total-milestones project) MAX-MILESTONES) ERR-MAX-MILESTONES)
            
            (map-set Milestones
                { project-id: project-id, milestone-id: (get total-milestones project) }
                {
                    description: description,
                    payment: payment,
                    status: "active",
                    deadline: (+ block-height DEPOSIT-LOCK-TIME)
                }
            )
            
            (map-set Projects
                { project-id: project-id }
                (merge project {
                    total-milestones: (+ (get total-milestones project) u1)
                }))
                
            (ok true))))

;; Complete milestone
(define-public (complete-milestone (project-id uint) (milestone-id uint))
    (begin
        (asserts! (is-valid-project-id project-id) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-milestone-id project-id milestone-id) ERR-INVALID-MILESTONE-ID)
        
        (let ((project (unwrap! (map-get? Projects { project-id: project-id }) ERR-INVALID-PROJECT))
              (milestone (unwrap! (map-get? Milestones { project-id: project-id, milestone-id: milestone-id }) 
                                ERR-STAGE-MISMATCH)))
            
            (asserts! (is-eq (get status milestone) "active") ERR-PROJECT-INACTIVE)
            (asserts! (is-eq tx-sender (get client project)) ERR-NOT-AUTHORIZED)
            
            (try! (as-contract (stx-transfer? (get payment milestone) 
                                            tx-sender 
                                            (get talent project))))
            
            (map-set Milestones
                { project-id: project-id, milestone-id: milestone-id }
                (merge milestone { status: "completed" }))
            
            (if (is-eq (+ (get completed-milestones project) u1) 
                      (get total-milestones project))
                (map-set Projects
                    { project-id: project-id }
                    (merge project {
                        status: "completed",
                        completion-time: block-height,
                        completed-milestones: (+ (get completed-milestones project) u1),
                        remaining-budget: (- (get remaining-budget project) (get payment milestone))
                    }))
                (map-set Projects
                    { project-id: project-id }
                    (merge project {
                        completed-milestones: (+ (get completed-milestones project) u1),
                        remaining-budget: (- (get remaining-budget project) (get payment milestone))
                    })))
            
            (ok true))))

;; Submit dispute evidence
(define-public (submit-dispute-evidence (project-id uint) (evidence-hash (buff 32)))
    (begin
        (asserts! (is-valid-project-id project-id) ERR-INVALID-PROJECT-ID)
        (asserts! (is-valid-evidence-hash evidence-hash) ERR-INVALID-EVIDENCE)
        
        (let ((project (unwrap! (map-get? Projects { project-id: project-id }) ERR-INVALID-PROJECT)))
            (asserts! (or (is-eq tx-sender (get client project))
                         (is-eq tx-sender (get talent project)))
                     ERR-NOT-AUTHORIZED)
            (map-set DisputeEvidence
                { project-id: project-id, party: tx-sender }
                {
                    evidence-hash: evidence-hash,
                    submit-time: block-height
                }
            )
            (ok true))))

;; Category management
(define-public (create-category 
    (name (string-ascii 64))
    (description (string-ascii 256))
    (min-deposit uint))
    
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-name name) ERR-INVALID-NAME)
        (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
        (asserts! (>= min-deposit MIN-DEPOSIT) ERR-INVALID-PAYMENT)
        
        (let ((category-id (+ (var-get category-counter) u1)))
            (map-set Categories
                { category-id: category-id }
                {
                    name: name,
                    description: description,
                    min-deposit: min-deposit
                }
            )
            (var-set category-counter category-id)
            (ok category-id))))

;; Read-only functions
(define-read-only (view-project (project-id uint))
    (map-get? Projects { project-id: project-id }))

(define-read-only (view-milestone (project-id uint) (milestone-id uint))
    (map-get? Milestones { project-id: project-id, milestone-id: milestone-id }))

(define-read-only (view-talent-rating (professional principal))
    (map-get? TalentRatings { professional: professional }))

(define-read-only (view-talent-stats (professional principal))
    (let ((rating (unwrap! (map-get? TalentRatings { professional: professional }) (err u8)))
          (deposit (map-get? TalentDeposits { professional: professional })))
        (ok {
            rating: rating,
            deposit: deposit
        })))

(define-read-only (view-category (category-id uint))
    (map-get? Categories { category-id: category-id }))

(define-read-only (view-dispute-evidence (project-id uint) (party principal))
    (map-get? DisputeEvidence { project-id: project-id, party: party }))