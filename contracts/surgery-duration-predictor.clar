;; title: surgery-duration-predictor
;; version: 1.0.0
;; summary: AI analysis of historical surgical data and automated OR scheduling optimization
;; description: This contract manages surgical scheduling optimization through AI-powered duration prediction and resource allocation.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_SURGERY_NOT_FOUND (err u501))
(define-constant ERR_INVALID_DURATION (err u502))
(define-constant ERR_INVALID_COMPLEXITY (err u503))
(define-constant ERR_OR_NOT_AVAILABLE (err u504))
(define-constant ERR_SURGEON_NOT_FOUND (err u505))
(define-constant ERR_SCHEDULE_CONFLICT (err u506))
(define-constant ERR_INVALID_PROCEDURE_TYPE (err u507))

(define-constant MAX_SURGERY_DURATION u1440) ;; 24 hours in minutes
(define-constant MIN_SURGERY_DURATION u15)   ;; 15 minutes minimum
(define-constant MAX_COMPLEXITY_LEVEL u10)
(define-constant MIN_COMPLEXITY_LEVEL u1)
(define-constant OPERATING_ROOMS_COUNT u20)
(define-constant PREDICTION_CONFIDENCE_THRESHOLD u80) ;; 80% minimum confidence

;; Surgery types
(define-constant SURGERY_CARDIAC "cardiac")
(define-constant SURGERY_ORTHOPEDIC "orthopedic")
(define-constant SURGERY_NEUROLOGICAL "neurological")
(define-constant SURGERY_GENERAL "general")
(define-constant SURGERY_ONCOLOGICAL "oncological")
(define-constant SURGERY_PEDIATRIC "pediatric")
(define-constant SURGERY_EMERGENCY "emergency")
(define-constant SURGERY_TRANSPLANT "transplant")
(define-constant SURGERY_RECONSTRUCTIVE "reconstructive")
(define-constant SURGERY_MINIMALLY_INVASIVE "minimally-invasive")

;; Surgeon experience levels
(define-constant EXPERIENCE_RESIDENT u1)
(define-constant EXPERIENCE_JUNIOR u2)
(define-constant EXPERIENCE_SENIOR u3)
(define-constant EXPERIENCE_ATTENDING u4)
(define-constant EXPERIENCE_SPECIALIST u5)

;; data vars
(define-data-var next-surgery-id uint u1)
(define-data-var next-schedule-id uint u1)
(define-data-var next-prediction-id uint u1)
(define-data-var total-surgeries uint u0)
(define-data-var total-predictions uint u0)
(define-data-var prediction-accuracy-rate uint u0)
(define-data-var average-or-utilization uint u0)

;; data maps
;; Historical surgery records for ML training
(define-map surgery-records
  { surgery-id: uint }
  {
    procedure-type: (string-ascii 64),
    actual-duration: uint,
    complexity-level: uint,
    surgeon-experience: uint,
    patient-age: uint,
    patient-bmi: uint,
    comorbidities-count: uint,
    emergency-status: bool,
    or-room-number: uint,
    start-time: uint,
    end-time: uint,
    complications-occurred: bool,
    surgery-date: uint,
    outcome-rating: uint
  }
)

;; Surgery duration predictions
(define-map duration-predictions
  { prediction-id: uint }
  {
    procedure-type: (string-ascii 64),
    predicted-duration: uint,
    confidence-score: uint,
    complexity-level: uint,
    surgeon-experience: uint,
    patient-factors: uint,
    prediction-model-version: uint,
    created-timestamp: uint,
    actual-duration: (optional uint),
    accuracy-score: (optional uint)
  }
)

;; Operating room schedules
(define-map or-schedules
  { schedule-id: uint }
  {
    or-room-number: uint,
    surgery-id: uint,
    scheduled-start: uint,
    scheduled-duration: uint,
    surgeon-principal: principal,
    procedure-type: (string-ascii 64),
    patient-id: (string-ascii 64),
    priority-level: uint,
    buffer-time: uint,
    status: (string-ascii 32),
    created-by: principal
  }
)

;; Surgeon profiles and performance metrics
(define-map surgeon-profiles
  { surgeon-principal: principal }
  {
    surgeon-name: (string-ascii 128),
    specialization: (string-ascii 64),
    experience-level: uint,
    years-practice: uint,
    average-surgery-duration: uint,
    surgery-count: uint,
    success-rate: uint,
    on-time-performance: uint,
    complexity-rating: uint,
    last-surgery-date: uint
  }
)

;; OR room utilization and performance
(define-map or-utilization
  { or-room-number: uint, date: uint }
  {
    total-scheduled-time: uint,
    actual-used-time: uint,
    number-of-surgeries: uint,
    turnover-time: uint,
    efficiency-rating: uint,
    downtime-minutes: uint,
    maintenance-scheduled: bool
  }
)

;; Procedure type statistics for predictions
(define-map procedure-statistics
  { procedure-type: (string-ascii 64) }
  {
    average-duration: uint,
    standard-deviation: uint,
    total-procedures: uint,
    success-rate: uint,
    complication-rate: uint,
    cancellation-rate: uint,
    revision-rate: uint,
    patient-satisfaction: uint
  }
)

;; Patient factors for duration prediction
(define-map patient-risk-factors
  { patient-id: (string-ascii 64) }
  {
    age: uint,
    bmi: uint,
    comorbidities: (string-ascii 256),
    previous-surgeries: uint,
    medication-count: uint,
    anesthesia-risk-score: uint,
    mobility-score: uint,
    cognitive-status: uint
  }
)

;; Machine learning model parameters
(define-map ml-model-parameters
  { model-version: uint }
  {
    training-data-size: uint,
    accuracy-rate: uint,
    confidence-threshold: uint,
    feature-weights: (string-ascii 512),
    model-type: (string-ascii 32),
    last-updated: uint,
    validation-score: uint,
    deployment-date: uint
  }
)

;; public functions

;; Register a new surgery record for machine learning training
(define-public (register-surgery-record
  (procedure-type (string-ascii 64))
  (actual-duration uint)
  (complexity-level uint)
  (surgeon-experience uint)
  (patient-age uint)
  (patient-bmi uint)
  (comorbidities-count uint)
  (emergency-status bool)
  (or-room-number uint)
  (complications-occurred bool)
  (outcome-rating uint)
  )
  (let 
    (
      (surgery-id (var-get next-surgery-id))
    )
    ;; Validate input parameters
    (asserts! (is-valid-procedure-type procedure-type) ERR_INVALID_PROCEDURE_TYPE)
    (asserts! (and (>= actual-duration MIN_SURGERY_DURATION) (<= actual-duration MAX_SURGERY_DURATION)) ERR_INVALID_DURATION)
    (asserts! (and (>= complexity-level MIN_COMPLEXITY_LEVEL) (<= complexity-level MAX_COMPLEXITY_LEVEL)) ERR_INVALID_COMPLEXITY)
    (asserts! (and (> or-room-number u0) (<= or-room-number OPERATING_ROOMS_COUNT)) (err u508))
    (asserts! (and (>= surgeon-experience u1) (<= surgeon-experience u5)) (err u509))
    
    ;; Store surgery record
    (map-set surgery-records
      {surgery-id: surgery-id}
      {
        procedure-type: procedure-type,
        actual-duration: actual-duration,
        complexity-level: complexity-level,
        surgeon-experience: surgeon-experience,
        patient-age: patient-age,
        patient-bmi: patient-bmi,
        comorbidities-count: comorbidities-count,
        emergency-status: emergency-status,
        or-room-number: or-room-number,
        start-time: stacks-block-height,
        end-time: (+ stacks-block-height actual-duration),
        complications-occurred: complications-occurred,
        surgery-date: stacks-block-height,
        outcome-rating: outcome-rating
      }
    )
    
    ;; Update procedure statistics
    (unwrap-panic (update-procedure-statistics procedure-type actual-duration outcome-rating complications-occurred))
    
    ;; Update counters
    (var-set next-surgery-id (+ surgery-id u1))
    (var-set total-surgeries (+ (var-get total-surgeries) u1))
    
    (ok surgery-id)
  )
)

;; Predict surgery duration using AI analysis
(define-public (predict-surgery-duration
  (procedure-type (string-ascii 64))
  (complexity-level uint)
  (surgeon-experience uint)
  (patient-age uint)
  (patient-bmi uint)
  (comorbidities-count uint)
  (emergency-status bool)
  )
  (let 
    (
      (prediction-id (var-get next-prediction-id))
      (base-duration (get-base-duration-for-procedure procedure-type))
      (complexity-factor (calculate-complexity-factor complexity-level))
      (experience-factor (calculate-experience-factor surgeon-experience))
      (patient-factor (calculate-patient-risk-factor patient-age patient-bmi comorbidities-count))
      (emergency-factor (if emergency-status u120 u100)) ;; 20% increase for emergency
      (predicted-duration (calculate-final-duration base-duration complexity-factor experience-factor patient-factor emergency-factor))
      (confidence-score (calculate-prediction-confidence procedure-type complexity-level surgeon-experience))
    )
    ;; Validate prediction confidence
    (asserts! (>= confidence-score PREDICTION_CONFIDENCE_THRESHOLD) (err u510))
    
    ;; Store prediction
    (map-set duration-predictions
      {prediction-id: prediction-id}
      {
        procedure-type: procedure-type,
        predicted-duration: predicted-duration,
        confidence-score: confidence-score,
        complexity-level: complexity-level,
        surgeon-experience: surgeon-experience,
        patient-factors: (+ patient-age patient-bmi comorbidities-count),
        prediction-model-version: u1,
        created-timestamp: stacks-block-height,
        actual-duration: none,
        accuracy-score: none
      }
    )
    
    ;; Update counters
    (var-set next-prediction-id (+ prediction-id u1))
    (var-set total-predictions (+ (var-get total-predictions) u1))
    
    (ok {prediction-id: prediction-id, predicted-duration: predicted-duration, confidence: confidence-score})
  )
)

;; Schedule surgery in OR with optimized timing
(define-public (schedule-surgery
  (or-room-number uint)
  (surgery-prediction-id uint)
  (surgeon-principal principal)
  (patient-id (string-ascii 64))
  (priority-level uint)
  (preferred-start-time uint)
  )
  (let 
    (
      (schedule-id (var-get next-schedule-id))
      (prediction (unwrap! (map-get? duration-predictions {prediction-id: surgery-prediction-id}) (err u511)))
      (predicted-duration (get predicted-duration prediction))
      (buffer-time (calculate-buffer-time predicted-duration priority-level))
      (total-duration (+ predicted-duration buffer-time))
    )
    ;; Validate OR availability
    (asserts! (is-or-available or-room-number preferred-start-time total-duration) ERR_OR_NOT_AVAILABLE)
    (asserts! (and (> or-room-number u0) (<= or-room-number OPERATING_ROOMS_COUNT)) (err u512))
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) (err u513))
    
    ;; Create schedule entry
    (map-set or-schedules
      {schedule-id: schedule-id}
      {
        or-room-number: or-room-number,
        surgery-id: surgery-prediction-id,
        scheduled-start: preferred-start-time,
        scheduled-duration: total-duration,
        surgeon-principal: surgeon-principal,
        procedure-type: (get procedure-type prediction),
        patient-id: patient-id,
        priority-level: priority-level,
        buffer-time: buffer-time,
        status: "scheduled",
        created-by: tx-sender
      }
    )
    
    ;; Update OR utilization
    (unwrap-panic (update-or-utilization or-room-number preferred-start-time total-duration))
    
    ;; Update schedule counter
    (var-set next-schedule-id (+ schedule-id u1))
    
    (ok schedule-id)
  )
)

;; Update prediction accuracy after surgery completion
(define-public (update-prediction-accuracy
  (prediction-id uint)
  (actual-duration uint)
  )
  (let 
    (
      (prediction (unwrap! (map-get? duration-predictions {prediction-id: prediction-id}) (err u514)))
      (predicted-duration (get predicted-duration prediction))
      (accuracy-score (calculate-accuracy-score predicted-duration actual-duration))
    )
    ;; Update prediction record
    (map-set duration-predictions
      {prediction-id: prediction-id}
      (merge prediction
        {
          actual-duration: (some actual-duration),
          accuracy-score: (some accuracy-score)
        }
      )
    )
    
    ;; Update global accuracy rate
    (unwrap-panic (update-global-accuracy-rate accuracy-score))
    
    (ok accuracy-score)
  )
)

;; Register surgeon profile
(define-public (register-surgeon
  (surgeon-name (string-ascii 128))
  (specialization (string-ascii 64))
  (experience-level uint)
  (years-practice uint)
  )
  (begin
    (asserts! (and (>= experience-level u1) (<= experience-level u5)) (err u515))
    (asserts! (<= years-practice u50) (err u516))
    
    (map-set surgeon-profiles
      {surgeon-principal: tx-sender}
      {
        surgeon-name: surgeon-name,
        specialization: specialization,
        experience-level: experience-level,
        years-practice: years-practice,
        average-surgery-duration: u0,
        surgery-count: u0,
        success-rate: u100,
        on-time-performance: u100,
        complexity-rating: experience-level,
        last-surgery-date: u0
      }
    )
    
    (ok true)
  )
)

;; read only functions

;; Get surgery record
(define-read-only (get-surgery-record (surgery-id uint))
  (map-get? surgery-records {surgery-id: surgery-id})
)

;; Get duration prediction
(define-read-only (get-duration-prediction (prediction-id uint))
  (map-get? duration-predictions {prediction-id: prediction-id})
)

;; Get OR schedule
(define-read-only (get-or-schedule (schedule-id uint))
  (map-get? or-schedules {schedule-id: schedule-id})
)

;; Get surgeon profile
(define-read-only (get-surgeon-profile (surgeon-principal principal))
  (map-get? surgeon-profiles {surgeon-principal: surgeon-principal})
)

;; Get procedure statistics
(define-read-only (get-procedure-statistics (procedure-type (string-ascii 64)))
  (map-get? procedure-statistics {procedure-type: procedure-type})
)

;; Get OR utilization
(define-read-only (get-or-utilization (or-room-number uint) (date uint))
  (map-get? or-utilization {or-room-number: or-room-number, date: date})
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-surgeries: (var-get total-surgeries),
    total-predictions: (var-get total-predictions),
    prediction-accuracy-rate: (var-get prediction-accuracy-rate),
    average-or-utilization: (var-get average-or-utilization),
    next-surgery-id: (var-get next-surgery-id),
    next-prediction-id: (var-get next-prediction-id)
  }
)

;; private functions

;; Validate procedure type
(define-private (is-valid-procedure-type (procedure-type (string-ascii 64)))
  (or
    (is-eq procedure-type SURGERY_CARDIAC)
    (is-eq procedure-type SURGERY_ORTHOPEDIC)
    (is-eq procedure-type SURGERY_NEUROLOGICAL)
    (is-eq procedure-type SURGERY_GENERAL)
    (is-eq procedure-type SURGERY_ONCOLOGICAL)
    (is-eq procedure-type SURGERY_PEDIATRIC)
    (is-eq procedure-type SURGERY_EMERGENCY)
    (is-eq procedure-type SURGERY_TRANSPLANT)
    (is-eq procedure-type SURGERY_RECONSTRUCTIVE)
    (is-eq procedure-type SURGERY_MINIMALLY_INVASIVE)
  )
)

;; Get base duration for procedure type
(define-private (get-base-duration-for-procedure (procedure-type (string-ascii 64)))
  (if (is-eq procedure-type SURGERY_CARDIAC)
    u360  ;; 6 hours
    (if (is-eq procedure-type SURGERY_NEUROLOGICAL)
      u480  ;; 8 hours
      (if (is-eq procedure-type SURGERY_TRANSPLANT)
        u720  ;; 12 hours
        (if (is-eq procedure-type SURGERY_ORTHOPEDIC)
          u180  ;; 3 hours
          (if (is-eq procedure-type SURGERY_ONCOLOGICAL)
            u240  ;; 4 hours
            u120  ;; 2 hours default
          )
        )
      )
    )
  )
)

;; Calculate complexity factor
(define-private (calculate-complexity-factor (complexity-level uint))
  (+ u100 (* complexity-level u10)) ;; 10% increase per complexity level
)

;; Calculate experience factor  
(define-private (calculate-experience-factor (experience-level uint))
  (- u120 (* experience-level u4)) ;; More experienced surgeons are faster
)

;; Calculate patient risk factor
(define-private (calculate-patient-risk-factor (age uint) (bmi uint) (comorbidities uint))
  (let 
    (
      (age-factor (if (> age u65) u110 u100))
      (bmi-factor (if (> bmi u30) u105 u100))
      (comorbidity-factor (+ u100 (* comorbidities u5)))
    )
    (/ (+ age-factor bmi-factor comorbidity-factor) u3)
  )
)

;; Calculate final duration with all factors
(define-private (calculate-final-duration (base uint) (complexity uint) (experience uint) (patient uint) (emergency uint))
  (/ (* base complexity experience patient emergency) u100000000)
)

;; Calculate prediction confidence
(define-private (calculate-prediction-confidence (procedure-type (string-ascii 64)) (complexity uint) (experience uint))
  (let 
    (
      (base-confidence u85)
      (complexity-adjustment (- u10 complexity))
      (experience-adjustment (* experience u2))
    )
    (+ base-confidence complexity-adjustment experience-adjustment)
  )
)

;; Calculate buffer time
(define-private (calculate-buffer-time (predicted-duration uint) (priority-level uint))
  (let 
    (
      (base-buffer (/ predicted-duration u10)) ;; 10% base buffer
      (priority-adjustment (- u6 priority-level)) ;; Higher priority gets less buffer
    )
    (+ base-buffer (* priority-adjustment u5))
  )
)

;; Check OR availability (simplified)
(define-private (is-or-available (or-room uint) (start-time uint) (duration uint))
  ;; Simplified check - in practice, this would check against existing schedules
  (and (> or-room u0) (<= or-room OPERATING_ROOMS_COUNT))
)

;; Calculate accuracy score
(define-private (calculate-accuracy-score (predicted uint) (actual uint))
  (let 
    (
      (difference (if (> predicted actual) (- predicted actual) (- actual predicted)))
      (percentage-error (/ (* difference u100) predicted))
    )
    (if (> percentage-error u100) u0 (- u100 percentage-error))
  )
)

;; Update procedure statistics
(define-private (update-procedure-statistics (procedure-type (string-ascii 64)) (duration uint) (outcome uint) (complications bool))
  (match (map-get? procedure-statistics {procedure-type: procedure-type})
    existing-stats
    (let 
      (
        (total-procedures (+ (get total-procedures existing-stats) u1))
        (total-duration (+ (* (get average-duration existing-stats) (get total-procedures existing-stats)) duration))
        (new-average (/ total-duration total-procedures))
      )
      (map-set procedure-statistics
        {procedure-type: procedure-type}
        (merge existing-stats
          {
            average-duration: new-average,
            total-procedures: total-procedures
          }
        )
      )
      (ok true)
    )
    ;; First record for this procedure type
    (begin
      (map-set procedure-statistics
        {procedure-type: procedure-type}
        {
          average-duration: duration,
          standard-deviation: u0,
          total-procedures: u1,
          success-rate: outcome,
          complication-rate: (if complications u100 u0),
          cancellation-rate: u0,
          revision-rate: u0,
          patient-satisfaction: u80
        }
      )
      (ok true)
    )
  )
)

;; Update OR utilization
(define-private (update-or-utilization (or-room uint) (start-time uint) (duration uint))
  (let 
    (
      (date (/ start-time u144)) ;; Approximate daily periods
    )
    (match (map-get? or-utilization {or-room-number: or-room, date: date})
      existing-util
      (map-set or-utilization
        {or-room-number: or-room, date: date}
        (merge existing-util
          {
            total-scheduled-time: (+ (get total-scheduled-time existing-util) duration),
            number-of-surgeries: (+ (get number-of-surgeries existing-util) u1)
          }
        )
      )
      ;; First surgery for this OR on this date
      (map-set or-utilization
        {or-room-number: or-room, date: date}
        {
          total-scheduled-time: duration,
          actual-used-time: u0,
          number-of-surgeries: u1,
          turnover-time: u30,
          efficiency-rating: u85,
          downtime-minutes: u0,
          maintenance-scheduled: false
        }
      )
    )
    (ok true)
  )
)

;; Update global accuracy rate
(define-private (update-global-accuracy-rate (new-accuracy uint))
  (let 
    (
      (current-rate (var-get prediction-accuracy-rate))
      (total-pred-count (var-get total-predictions))
      (new-rate (if (is-eq total-pred-count u1)
                  new-accuracy
                  (/ (+ (* current-rate (- total-pred-count u1)) new-accuracy) total-pred-count)))
    )
    (var-set prediction-accuracy-rate new-rate)
    (ok true)
  )
)
