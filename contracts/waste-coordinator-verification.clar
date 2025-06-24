;; Waste Coordinator Verification Contract
;; Manages verification and authorization of waste management coordinators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map coordinators
  { coordinator: principal }
  {
    verified: bool,
    verification-date: uint,
    credentials-hash: (buff 32),
    region: (string-ascii 50),
    specialization: (string-ascii 100)
  }
)

(define-map coordinator-stats
  { coordinator: principal }
  {
    collections-completed: uint,
    efficiency-score: uint,
    last-activity: uint
  }
)

(define-data-var total-coordinators uint u0)

;; Public functions
(define-public (verify-coordinator
  (coordinator principal)
  (credentials-hash (buff 32))
  (region (string-ascii 50))
  (specialization (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? coordinators { coordinator: coordinator })) ERR_ALREADY_VERIFIED)

    (map-set coordinators
      { coordinator: coordinator }
      {
        verified: true,
        verification-date: block-height,
        credentials-hash: credentials-hash,
        region: region,
        specialization: specialization
      }
    )

    (map-set coordinator-stats
      { coordinator: coordinator }
      {
        collections-completed: u0,
        efficiency-score: u100,
        last-activity: block-height
      }
    )

    (var-set total-coordinators (+ (var-get total-coordinators) u1))
    (ok true)
  )
)

(define-public (update-coordinator-activity (coordinator principal))
  (let ((coordinator-data (unwrap! (map-get? coordinators { coordinator: coordinator }) ERR_NOT_FOUND)))
    (asserts! (get verified coordinator-data) ERR_UNAUTHORIZED)

    (map-set coordinator-stats
      { coordinator: coordinator }
      (merge
        (default-to
          { collections-completed: u0, efficiency-score: u100, last-activity: block-height }
          (map-get? coordinator-stats { coordinator: coordinator })
        )
        { last-activity: block-height }
      )
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-coordinator (coordinator principal))
  (match (map-get? coordinators { coordinator: coordinator })
    coordinator-data (get verified coordinator-data)
    false
  )
)

(define-read-only (get-coordinator-info (coordinator principal))
  (map-get? coordinators { coordinator: coordinator })
)

(define-read-only (get-coordinator-stats (coordinator principal))
  (map-get? coordinator-stats { coordinator: coordinator })
)

(define-read-only (get-total-coordinators)
  (var-get total-coordinators)
)
