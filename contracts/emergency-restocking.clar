;; Emergency Restocking Contract
;; Handles urgent supply needs and emergency orders

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-INPUT (err u501))
(define-constant ERR-EMERGENCY-NOT-FOUND (err u502))
(define-constant ERR-SUPPLIER-NOT-FOUND (err u503))
(define-constant ERR-INSUFFICIENT-PRIORITY (err u504))
(define-constant ERR-EMERGENCY-RESOLVED (err u505))

;; Data Variables
(define-data-var next-emergency-id uint u1)
(define-data-var next-supplier-id uint u1)
(define-data-var next-allocation-id uint u1)

;; Data Maps
(define-map emergency-requests
  { emergency-id: uint }
  {
    item-id: uint,
    requested-quantity: uint,
    urgency-level: uint,
    reason: (string-ascii 300),
    requested-by: principal,
    request-date: uint,
    required-by-date: uint,
    status: (string-ascii 30),
    approved-by: (optional principal),
    approval-date: (optional uint)
  }
)

(define-map emergency-suppliers
  { supplier-id: uint }
  {
    name: (string-ascii 100),
    contact-info: (string-ascii 200),
    response-time-hours: uint,
    reliability-score: uint,
    specialties: (list 10 (string-ascii 50)),
    active: bool,
    emergency-contact: (string-ascii 200)
  }
)

(define-map crisis-inventory
  { item-id: uint }
  {
    reserved-quantity: uint,
    crisis-threshold: uint,
    last-updated: uint,
    allocation-priority: uint,
    restricted-access: bool
  }
)

(define-map priority-allocations
  { allocation-id: uint }
  {
    emergency-id: uint,
    item-id: uint,
    allocated-quantity: uint,
    allocation-date: uint,
    allocated-by: principal,
    priority-score: uint,
    department: (string-ascii 50),
    justification: (string-ascii 300)
  }
)

(define-map emergency-orders
  { emergency-id: uint }
  {
    supplier-id: uint,
    order-date: uint,
    expected-delivery: uint,
    expedite-fee: uint,
    tracking-info: (string-ascii 100),
    delivery-status: (string-ascii 30)
  }
)

(define-map authorized-staff principal bool)
(define-map emergency-approvers principal bool)

;; Authorization Functions
(define-public (authorize-staff (staff principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-staff staff true))
  )
)

(define-public (authorize-emergency-approver (approver principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set emergency-approvers approver true))
  )
)

(define-private (is-authorized (user principal))
  (or
    (is-eq user CONTRACT-OWNER)
    (default-to false (map-get? authorized-staff user))
  )
)

(define-private (is-emergency-approver (user principal))
  (or
    (is-eq user CONTRACT-OWNER)
    (default-to false (map-get? emergency-approvers user))
  )
)

;; Emergency Request Functions
(define-public (create-emergency-request (item-id uint) (requested-quantity uint) (urgency-level uint) (reason (string-ascii 300)) (required-by-date uint))
  (let ((emergency-id (var-get next-emergency-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> requested-quantity u0) ERR-INVALID-INPUT)
    (asserts! (and (>= urgency-level u1) (<= urgency-level u5)) ERR-INVALID-INPUT)
    (asserts! (> (len reason) u0) ERR-INVALID-INPUT)
    (asserts! (> required-by-date block-height) ERR-INVALID-INPUT)

    (map-set emergency-requests
      { emergency-id: emergency-id }
      {
        item-id: item-id,
        requested-quantity: requested-quantity,
        urgency-level: urgency-level,
        reason: reason,
        requested-by: tx-sender,
        request-date: block-height,
        required-by-date: required-by-date,
        status: "pending",
        approved-by: none,
        approval-date: none
      }
    )
    (var-set next-emergency-id (+ emergency-id u1))
    (ok emergency-id)
  )
)

(define-public (approve-emergency-request (emergency-id uint))
  (let ((request (unwrap! (map-get? emergency-requests { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (is-emergency-approver tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-EMERGENCY-RESOLVED)

    (map-set emergency-requests
      { emergency-id: emergency-id }
      (merge request {
        status: "approved",
        approved-by: (some tx-sender),
        approval-date: (some block-height)
      })
    )
    (ok true)
  )
)

(define-public (reject-emergency-request (emergency-id uint) (rejection-reason (string-ascii 200)))
  (let ((request (unwrap! (map-get? emergency-requests { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (is-emergency-approver tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-EMERGENCY-RESOLVED)
    (asserts! (> (len rejection-reason) u0) ERR-INVALID-INPUT)

    (map-set emergency-requests
      { emergency-id: emergency-id }
      (merge request { status: "rejected" })
    )
    (ok true)
  )
)

;; Emergency Supplier Functions
(define-public (register-emergency-supplier (name (string-ascii 100)) (contact-info (string-ascii 200)) (response-time-hours uint) (specialties (list 10 (string-ascii 50))) (emergency-contact (string-ascii 200)))
  (let ((supplier-id (var-get next-supplier-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len contact-info) u0) ERR-INVALID-INPUT)
    (asserts! (> response-time-hours u0) ERR-INVALID-INPUT)

    (map-set emergency-suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        contact-info: contact-info,
        response-time-hours: response-time-hours,
        reliability-score: u5,
        specialties: specialties,
        active: true,
        emergency-contact: emergency-contact
      }
    )
    (var-set next-supplier-id (+ supplier-id u1))
    (ok supplier-id)
  )
)

(define-public (update-supplier-reliability (supplier-id uint) (new-score uint))
  (let ((supplier (unwrap! (map-get? emergency-suppliers { supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-score u10) ERR-INVALID-INPUT)

    (map-set emergency-suppliers
      { supplier-id: supplier-id }
      (merge supplier { reliability-score: new-score })
    )
    (ok true)
  )
)

;; Crisis Inventory Functions
(define-public (set-crisis-inventory (item-id uint) (reserved-quantity uint) (crisis-threshold uint) (allocation-priority uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> crisis-threshold u0) ERR-INVALID-INPUT)
    (asserts! (and (>= allocation-priority u1) (<= allocation-priority u5)) ERR-INVALID-INPUT)

    (map-set crisis-inventory
      { item-id: item-id }
      {
        reserved-quantity: reserved-quantity,
        crisis-threshold: crisis-threshold,
        last-updated: block-height,
        allocation-priority: allocation-priority,
        restricted-access: false
      }
    )
    (ok true)
  )
)

(define-public (restrict-crisis-item (item-id uint) (restricted bool))
  (let ((crisis-item (unwrap! (map-get? crisis-inventory { item-id: item-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (is-emergency-approver tx-sender) ERR-NOT-AUTHORIZED)

    (map-set crisis-inventory
      { item-id: item-id }
      (merge crisis-item {
        restricted-access: restricted,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Priority Allocation Functions
(define-public (allocate-emergency-supply (emergency-id uint) (allocated-quantity uint) (department (string-ascii 50)) (justification (string-ascii 300)))
  (let
    (
      (allocation-id (var-get next-allocation-id))
      (request (unwrap! (map-get? emergency-requests { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
      (item-id (get item-id request))
      (crisis-item (map-get? crisis-inventory { item-id: item-id }))
    )
    (asserts! (is-emergency-approver tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "approved") ERR-INSUFFICIENT-PRIORITY)
    (asserts! (<= allocated-quantity (get requested-quantity request)) ERR-INVALID-INPUT)
    (asserts! (> allocated-quantity u0) ERR-INVALID-INPUT)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)
    (asserts! (> (len justification) u0) ERR-INVALID-INPUT)

    ;; Check if item has restricted access
    (match crisis-item
      item (asserts! (not (get restricted-access item)) ERR-NOT-AUTHORIZED)
      true
    )

    (let ((priority-score (get urgency-level request)))
      (map-set priority-allocations
        { allocation-id: allocation-id }
        {
          emergency-id: emergency-id,
          item-id: item-id,
          allocated-quantity: allocated-quantity,
          allocation-date: block-height,
          allocated-by: tx-sender,
          priority-score: priority-score,
          department: department,
          justification: justification
        }
      )
      (var-set next-allocation-id (+ allocation-id u1))

      ;; Update emergency request status
      (map-set emergency-requests
        { emergency-id: emergency-id }
        (merge request { status: "allocated" })
      )
    )
    (ok allocation-id)
  )
)

;; Emergency Order Functions
(define-public (place-emergency-order (emergency-id uint) (supplier-id uint) (expected-delivery uint) (expedite-fee uint))
  (let
    (
      (request (unwrap! (map-get? emergency-requests { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
      (supplier (unwrap! (map-get? emergency-suppliers { supplier-id: supplier-id }) ERR-SUPPLIER-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "approved") ERR-INSUFFICIENT-PRIORITY)
    (asserts! (get active supplier) ERR-SUPPLIER-NOT-FOUND)
    (asserts! (> expected-delivery block-height) ERR-INVALID-INPUT)

    (map-set emergency-orders
      { emergency-id: emergency-id }
      {
        supplier-id: supplier-id,
        order-date: block-height,
        expected-delivery: expected-delivery,
        expedite-fee: expedite-fee,
        tracking-info: "",
        delivery-status: "ordered"
      }
    )

    ;; Update request status
    (map-set emergency-requests
      { emergency-id: emergency-id }
      (merge request { status: "ordered" })
    )
    (ok true)
  )
)

(define-public (update-emergency-order-tracking (emergency-id uint) (tracking-info (string-ascii 100)) (delivery-status (string-ascii 30)))
  (let ((order (unwrap! (map-get? emergency-orders { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len delivery-status) u0) ERR-INVALID-INPUT)

    (map-set emergency-orders
      { emergency-id: emergency-id }
      (merge order {
        tracking-info: tracking-info,
        delivery-status: delivery-status
      })
    )
    (ok true)
  )
)

(define-public (complete-emergency-delivery (emergency-id uint) (delivered-quantity uint))
  (let
    (
      (request (unwrap! (map-get? emergency-requests { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
      (order (unwrap! (map-get? emergency-orders { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> delivered-quantity u0) ERR-INVALID-INPUT)

    ;; Update order status
    (map-set emergency-orders
      { emergency-id: emergency-id }
      (merge order { delivery-status: "delivered" })
    )

    ;; Update request status
    (map-set emergency-requests
      { emergency-id: emergency-id }
      (merge request { status: "completed" })
    )
    (ok true)
  )
)

;; Crisis Management Functions
(define-public (declare-supply-crisis (item-id uint) (crisis-level uint))
  (begin
    (asserts! (is-emergency-approver tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= crisis-level u1) (<= crisis-level u5)) ERR-INVALID-INPUT)

    ;; Automatically restrict access for high crisis levels
    (if (>= crisis-level u4)
      (unwrap-panic (restrict-crisis-item item-id true))
      true
    )
    (ok true)
  )
)

(define-public (calculate-emergency-priority (urgency-level uint) (required-by-date uint) (department-priority uint))
  (let
    (
      (time-factor (if (< required-by-date (+ block-height u24)) u2 u1)) ;; 24 blocks = urgent
      (priority-score (+ (* urgency-level u2) (* time-factor u3) department-priority))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= urgency-level u1) (<= urgency-level u5)) ERR-INVALID-INPUT)
    (asserts! (and (>= department-priority u1) (<= department-priority u3)) ERR-INVALID-INPUT)

    (ok priority-score)
  )
)

;; Read-only Functions
(define-read-only (get-emergency-request (emergency-id uint))
  (map-get? emergency-requests { emergency-id: emergency-id })
)

(define-read-only (get-emergency-supplier (supplier-id uint))
  (map-get? emergency-suppliers { supplier-id: supplier-id })
)

(define-read-only (get-crisis-inventory (item-id uint))
  (map-get? crisis-inventory { item-id: item-id })
)

(define-read-only (get-priority-allocation (allocation-id uint))
  (map-get? priority-allocations { allocation-id: allocation-id })
)

(define-read-only (get-emergency-order (emergency-id uint))
  (map-get? emergency-orders { emergency-id: emergency-id })
)

(define-read-only (is-crisis-item (item-id uint))
  (is-some (map-get? crisis-inventory { item-id: item-id }))
)

(define-read-only (get-fastest-supplier (specialties (list 10 (string-ascii 50))))
  ;; Simplified implementation - would normally search through suppliers
  (some u1) ;; Return first supplier ID as example
)

(define-read-only (calculate-delivery-time (supplier-id uint) (urgency-level uint))
  (match (map-get? emergency-suppliers { supplier-id: supplier-id })
    supplier
      (let ((base-time (get response-time-hours supplier)))
        (if (>= urgency-level u4)
          (/ base-time u2) ;; Rush delivery
          base-time))
    u24 ;; Default 24 hours
  )
)

(define-read-only (get-next-emergency-id)
  (var-get next-emergency-id)
)

(define-read-only (get-next-supplier-id)
  (var-get next-supplier-id)
)

;; Initialize contract owner as authorized staff and emergency approver
(map-set authorized-staff CONTRACT-OWNER true)
(map-set emergency-approvers CONTRACT-OWNER true)
