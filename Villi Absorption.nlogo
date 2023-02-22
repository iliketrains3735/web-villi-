globals [
  tick-advance-amount               ; how much we advance the tick counter this time through
  max-tick-advance-amount           ; the largest tick-advance-amount is allowed to be
  init-avg-speed init-avg-energy    ; initial averages

  particle-size
  toggle-red-state
  toggle-green-state
  min-particle-energy
  max-particle-energy
  particles-to-add
  show-wall-hits?
  max-particles
  #particles
  #-green-particles
  #-purple-particles
  #-orange-particles
  villi-slider-moved?
  old-villi-slider-value
  bottom-wall-ycor
  tracker-init-particles
  permeability
  particle-to-watch
  total-initial-particles
  total-absorbed-particles
]


breed [ particles particle ]
breed [ flows flow ]
breed [ walls wall ]
breed [ edges edge ]



particles-own [
  speed mass energy          ; particles info
  last-collision
  color-type
  absorbed?
  swept?
  large?
]

patches-own [
  is-blood?
  blood-heading

]


walls-own [
  energy
  valve-1?
  valve-2?
  pressure?
  surface-energy
]

to setup
  clear-all
  reset-ticks
  ask patches [set pcolor white]
  set particle-size 2
  set max-tick-advance-amount 0.02
  set show-wall-hits? false
  set particles-to-add 2
  set old-villi-slider-value villi-height
  set villi-slider-moved? true
  set bottom-wall-ycor min-pycor + 3
  set-default-shape walls "cell"


  set tracker-init-particles initial-#-small-food-particles
  set permeability 50
  set particle-to-watch nobody


  redraw-villi?
  draw-blood-stream
  draw-edges
  make-small-particles
  make-large-particles
  set  total-initial-particles count particles
  set  total-absorbed-particles 0



  do-plotting
end


to go

  if ticks < end-simulation-at [
  redraw-villi?

    ask particles with [not absorbed?] [ bounce ]
    ask flows [move-flows]
    ask particles with [not absorbed?] [ move ]
    ask particles with [absorbed?  and pycor != min-pycor] [seep-toward-blood]
    ask particles with [swept?] [sweep-with-blood]
  ;  ask particles with [not absorbed?] [ check-for-collision ]
    ask particles with [not absorbed? and any? walls-here ] [ rewind-to-bounce ]
    ask particles with [not absorbed? and any? walls-here ] [ remove-from-walls ]

    check-watched-particle

  tick-advance tick-advance-amount
  calculate-tick-advance-amount
  check-particle-flow-out-of-system


  do-plotting
  display
  ]
end

to check-watched-particle
  if particle-to-watch != nobody [
  ask particle-to-watch [
      if pycor = max-pycor [rp]
    ]

    ]
end

to check-particle-flow-out-of-system
  ask particles [
    if pxcor = max-pxcor and visualize-food-in-blood-flow-as = "going someplace else" [set total-absorbed-particles total-absorbed-particles + 1 set hidden? true]
  ]

end



to watch-a-particle
  set particle-to-watch one-of particles with [pycor < (max-pycor - 2)]
  if count particles > 0 [
    watch one-of particles

  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;BUILD VILLI   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to shove-particles
  ask particles-here with [pycor <= (bottom-wall-ycor + villi-height)] [set ycor (bottom-wall-ycor + villi-height)]
end

to add-wall
  shove-particles
          sprout 1 [
          set breed walls set color gray
          ;set is-blood? false
          initialize-this-wall
        ]
end

to add-hidden-wall
  shove-particles
          sprout 1 [
          set breed walls set color gray
          set is-blood? false
          set hidden? true
          initialize-this-wall
        ]
end


to initialize-blood
          set breed walls set color red
          set size 1.0
          set is-blood? true
          set heading 90
          set shape "square"
          set color [255 0 0 150]
end

to add-blood-up
  shove-particles
  set blood-heading 0
  set is-blood? true
  sprout 1 [initialize-blood ]
end

to add-blood-down
  shove-particles
  set blood-heading 180
  set is-blood? true
  sprout 1 [initialize-blood]
end

to add-blood-right
  shove-particles
  set blood-heading 90
  set is-blood? true
  sprout 1 [initialize-blood]
end


to redraw-villi?
  if old-villi-slider-value != villi-height [set villi-slider-moved? true set old-villi-slider-value villi-height]
  if villi-slider-moved? [
     redraw-villi
     set villi-slider-moved? false
  ]
end

to redraw-villi
  ask walls with [pycor >= (min-pycor + 3)] [die]
  ask patches with [pycor >= (min-pycor + 3)] [set is-blood? false]
   ;; draw horizontal line until reaching a point where a villi is... then call villi build...skip and continue

   let distance-between-villi 5

    ask patches with [pxcor >= min-pxcor and pxcor <= max-pxcor and pycor = max-pycor ]  [add-hidden-wall]


     let this-pxcor min-pxcor
     let this-pycor bottom-wall-ycor
     let villi-width 5
     let this-width-counter 0
     let this-lift false
   repeat (max-pxcor - min-pxcor + 1)  [

    ifelse ((this-pxcor mod 11 >= 0) and (this-pxcor mod 11 <= 4)) and (this-pxcor >= (min-pxcor + 3) and this-pxcor <= (max-pxcor - 5))
         [set this-pycor (bottom-wall-ycor + villi-height) set this-lift true]
         [set this-pycor bottom-wall-ycor]
    ask patches with [pxcor = this-pxcor and pycor = this-pycor] [add-wall]

    ;; draw-vertical wall
    if this-lift [
        ask patches with [pxcor = this-pxcor and pycor >= bottom-wall-ycor and pycor <= this-pycor] [
          if (this-pxcor mod 11 = 0 and pycor < (this-pycor)) [add-wall]
          if (this-pxcor mod 11 = 1 and pycor < (this-pycor - 1)) [add-blood-up]
          if (this-pxcor mod 11 = 2 and pycor < (this-pycor - 2))[add-wall]
          if ((this-pxcor mod 11 = 2 or this-pxcor mod 11 = 1) and (pycor = (this-pycor - 1) ))[add-blood-right]
         if ((this-pxcor mod 11 = 2 ) and ( pycor = (this-pycor - 2)))[add-blood-right]
          if (this-pxcor mod 11 = 3 and pycor <= (this-pycor - 1)) [add-blood-down]
          if (this-pxcor mod 11 = 4 and pycor < (this-pycor)) [add-wall]
        ]
      set this-lift false
      ]
    set this-pxcor this-pxcor + 1
   ]


end

to draw-blood-stream
  let blood-patches patches with [pxcor >= min-pxcor and pxcor <= max-pxcor and pycor < bottom-wall-ycor and pycor >= min-pycor ]
  ask blood-patches [add-blood-right]
  ask n-of 30 blood-patches [
    make-a-floater
  ]
end

to make-a-floater
  let this-color (5 + random-float 20)
  let this-list [0 0 0]
  set this-list lput  this-color this-list
  sprout 1 [
    set breed flows
  set color this-list
  set shape "square"
  ]
end

to draw-edges
  ask patches with [pycor = (max-pycor) and pxcor < max-pxcor ][
    sprout 1 [
      set breed edges
      set shape "square 3"
      set size 1.05
      set color gray + 2
    ]
  ]
   ask patches with [pycor < (max-pycor) and pxcor = max-pxcor ][
    sprout 1 [
      set breed edges
      set shape "square 4"
      set size 1.05
      set color gray + 2
    ]
  ]
     ask patches with [pycor =(max-pycor) and pxcor = max-pxcor ][
     sprout 1 [
      set breed edges
      set shape "square"
      set size 1.05
      set color gray + 2
    ]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WALL INTERACTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GAS MOLECULES MOVEMENT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to bounce  ; particles procedure
  ; get the coordinates of the patch we'll be on if we go forward 1
  let bounce-patch nobody
  let bounce-patches nobody
  let hit-angle 0
  let this-patch patch-here
  let new-px 0
  let new-py 0
  let visible-wall nobody

  set bounce-patch  min-one-of walls in-cone ((sqrt (2)) / 2) 180 with [ patch-here != this-patch ] [ distance myself ]

  if bounce-patch != nobody [
    set new-px [ pxcor ] of bounce-patch
    set new-py [ pycor ] of bounce-patch
    set visible-wall walls-on bounce-patch

    if any? visible-wall  [
      ifelse (random 100 > permeability or (pycor >= (max-pycor - 1) ) or large? ) [
      if bounce-patch != patch-here [ set hit-angle towards bounce-patch ] ;; new bounce patch code
      ifelse (hit-angle <= 135 and hit-angle >= 45) or (hit-angle <= 315 and hit-angle >= 225) [
        set heading (- heading)
      ][
        set heading (180 - heading)
      ]

      set absorbed? false]
      [set absorbed? true]
    ]


  ]
end


to rewind-to-bounce  ; particles procedure
  ; attempts to deal with particle penetration by rewinding the particle path back to a point
  ; where it is about to hit a wall
  ; the particle path is reversed 49% of the previous tick-advance-amount it made,
  ; then particle collision with the wall is detected again.
  ; and the particle bounces off the wall using the remaining 51% of the tick-advance-amount.
  ; this use of slightly more of the tick-advance-amount for forward motion off the wall, helps
  ; insure the particle doesn't get stuck inside the wall on the bounce.

  let bounce-patch nobody
  let bounce-patches nobody
  let hit-angle 0
  let this-patch nobody
  let new-px 0
  let new-py 0
  let visible-wall nobody

  bk (speed) * tick-advance-amount * .49
  set this-patch  patch-here

  set bounce-patch  min-one-of walls in-cone ((sqrt (2)) / 2) 180 with [ self != this-patch ] [ distance myself ]

  if bounce-patch != nobody [

    set new-px [pxcor] of bounce-patch
    set new-py [pycor] of bounce-patch
    set visible-wall walls-on bounce-patch

    if any? visible-wall with [not hidden?] [
      set hit-angle towards bounce-patch

      ifelse (hit-angle <= 135 and hit-angle >= 45) or (hit-angle <= 315 and hit-angle >= 225) [
        set heading (- heading)
      ][
        set heading (180 - heading)
      ]


    ]
  ]
  fd (speed) * tick-advance-amount * 0.75
end

to move  ; particles procedure
  if patch-ahead (speed * tick-advance-amount) != patch-here [ set last-collision nobody ]
  ifelse (not large?) [rt random 30 lt random 30][rt random 10 lt random 10]
  fd (speed * tick-advance-amount * 0.75)
  if ycor >  (bottom-wall-ycor + villi-height) [set xcor xcor - .05]
end


to move-flows
  set heading 90
  fd (7 * tick-advance-amount * 0.75)

end

to seep-toward-blood
  let flex-threshold .2 + random-float .05
  let all-blood patches with [is-blood?]
  let target-blood-patch min-one-of all-blood [distance myself  ]
 ; show distance target-blood
  let final-heading towards target-blood-patch
  let heading-difference ((final-heading - heading) / 20)
  set heading heading + heading-difference
  let blood-near-me all-blood with [distance myself < flex-threshold]
  ifelse not any? blood-near-me [fd (2 * tick-advance-amount) ][set swept? true]
end

to sweep-with-blood
  let old-heading heading
  let heading-difference ((old-heading - heading) / 20)
  if (is-blood? and swept?)  [set heading blood-heading fd (3 * tick-advance-amount) set heading heading + heading-difference]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GAS MOLECULES COLLISIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;from GasLab

to calculate-tick-advance-amount
  ; tick-advance-amount is calculated in such way that even the fastest
  ; particles will jump at most 1 patch delta in a ticks tick. As
  ; particles jump (speed * tick-advance-amount) at every ticks tick, making
  ; tick delta the inverse of the speed of the fastest particles
  ; (1/max speed) assures that. Having each particles advance at most
  ; one patch-delta is necessary for it not to "jump over" a wall
  ; or another particles.
  ifelse any? particles with [ speed > 0 ] [
    set tick-advance-amount min list (1 / (ceiling max [speed] of particles )) max-tick-advance-amount
  ][
    set tick-advance-amount max-tick-advance-amount
  ]
end

to check-for-collision  ; particles procedure
  ; Here we impose a rule that collisions only take place when there
  ; are exactly two particles per patch.  We do this because when the
  ; student introduces new particles from the side, we want them to
  ; form a uniform wavefront.
  ;
  ; Why do we want a uniform wavefront?  Because it is actually more
  ; realistic.  (And also because the curriculum uses the uniform
  ; wavefront to help teach the relationship between particles collisions,
  ; wall hits, and pressure.)
  ;
  ; Why is it realistic to assume a uniform wavefront?  Because in reality,
  ; whether a collision takes place would depend on the actual headings
  ; of the particles, not merely on their proximity.  Since the particles
  ; in the wavefront have identical speeds and near-identical headings,
  ; in reality they would not collide.  So even though the two-particles
  ; rule is not itself realistic, it produces a realistic result.  Also,
  ; unless the number of particles is extremely large, it is very rare
  ; for three or  particles to land on the same patch (for example,
  ; with 400 particles it happens less than 1% of the time).  So imposing
  ; this additional rule should have only a negligible effect on the
  ; aggregate behavior of the system.
  ;
  ; Why does this rule produce a uniform wavefront?  The particles all
  ; start out on the same patch, which means that without the only-two
  ; rule, they would all start colliding with each other immediately,
  ; resulting in much random variation of speeds and headings.  With
  ; the only-two rule, they are prevented from colliding with each other
  ; until they have spread out a lot.  (And in fact, if you observe
  ; the wavefront closely, you will see that it is not completely smooth,
  ; because  collisions eventually do start occurring when it thins out while fanning.)

  if count other particles-here  in-radius 1 = 1 [
    ; the following conditions are imposed on collision candidates:
    ;   1. they must have a lower who number than my own, because collision
    ;      code is asymmetrical: it must always happen from the point of view
    ;      of just one particles.
    ;   2. they must not be the same particles that we last collided with on
    ;      this patch, so that we have a chance to leave the patch after we've
    ;      collided with someone.
    let candidate one-of other particles-here with [ who < [ who ] of myself and myself != last-collision ]
    ;; we also only collide if one of us has non-zero speed. It's useless
    ;; (and incorrect, actually) for two particles with zero speed to collide.
    if (candidate != nobody) and (speed > 0 or [ speed ] of candidate > 0) [
      collide-with candidate
      set last-collision candidate
      ask candidate [ set last-collision myself ]
    ]
  ]
end

; implements a collision with another particles.
;
; THIS IS THE HEART OF THE particles SIMULATION, AND YOU ARE STRONGLY ADVISED
; NOT TO CHANGE IT UNLESS YOU REALLY UNDERSTAND WHAT YOU'RE DOING!
;
; The two particles colliding are self and other-particles, and while the
; collision is performed from the point of view of self, both particles are
; modified to reflect its effects. This is somewhat complicated, so I'll
; give a general outline here:
;   1. Do initial setup, and determine the heading between particles centers
;      (call it theta).
;   2. Convert the representation of the velocity of each particles from
;      speed/heading to a theta-based vector whose first component is the
;      particle's speed along theta, and whose second component is the speed
;      perpendicular to theta.
;   3. Modify the velocity vectors to reflect the effects of the collision.
;      This involves:
;        a. computing the velocity of the center of mass of the whole system
;           along direction theta
;        b. updating the along-theta components of the two velocity vectors.
;   4. Convert from the theta-based vector representation of velocity back to
;      the usual speed/heading representation for each particles.
;   5. Perform final cleanup and update derived quantities.
to collide-with [ other-particles ] ;; particles procedure
  ; PHASE 1: initial setup

  ; for convenience, grab  quantities from other-particles
  let mass2 [ mass ] of other-particles
  let speed2 [ speed ] of other-particles
  let heading2 [ heading ] of other-particles

  ; since particles are modeled as zero-size points, theta isn't meaningfully
  ; defined. we can assign it randomly without affecting the model's outcome.
  let theta (random-float 360)

  ; PHASE 2: convert velocities to theta-based vector representation

  ; now convert my velocity from speed/heading representation to components
  ; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))

  ;; do the same for other-particles
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))

  ; PHASE 3: manipulate vectors to implement collision

  ; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

  ; now compute the new velocity for each particles along direction theta.
  ; velocity perpendicular to theta is unaffected by a collision along theta,
  ; so the next two lines actually implement the collision itself, in the
  ; sense that the effects of the collision are exactly the following changes
  ; in particles velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)

  ; PHASE 4: convert back to normal speed/heading

  ; now convert my velocity vector into my new speed and heading
  set speed sqrt ((v1t ^ 2) + (v1l ^ 2))
  set energy (0.5 * mass * speed ^ 2)
  ; if the magnitude of the velocity vector is 0, atan is undefined. but
  ; speed will be 0, so heading is irrelevant anyway. therefore, in that
  ; case we'll just leave it unmodified.
  if v1l != 0 or v1t != 0 [ set heading (theta - (atan v1l v1t)) ]

  ;; and do the same for other-particle
  ask other-particles [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy (0.5 * mass * (speed ^ 2))
    if v2l != 0 or v2t != 0 [ set heading (theta - (atan v2l v2t)) ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  initialization procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to initialize-this-wall
;  set valve-1? false
 ; set valve-2? false
;  set pressure? false
  ifelse random 2 = 0 [set shape "cell"][set shape "cell2"]
  set color [255 255 255 120]
  let turn random 4
  rt (turn * 90)
end

to make-small-particles
  create-particles initial-#-small-food-particles [
    setup-particles false
    set shape "small-molecule"
    random-position
  ]
end

to make-large-particles
  create-particles initial-#-large-food-particles [
    setup-particles true
    set shape "large-molecule"
    random-position
  ]
end


to setup-particles  [is-large]; particles procedure
 ; set shape "circle"
  set size particle-size
  set energy 150
  set color-type (violet - 3)
  set color color-type
  set mass (10)  ; atomic masses of oxygen atoms

  set speed speed-from-energy
  set last-collision nobody
  set absorbed? false
  set large? is-large
  set swept? false
end


; Place particles at random, but they must not be placed on top of wall atoms.
; This procedure takes into account the fact that wall molecules could have two possible arrangements,
; i.e. high-surface area ot low-surface area.
to random-position ;; particles procedure
  let open-patches nobody
  let open-patch nobody
  set open-patches patches with [not any? turtles-here and pxcor != max-pxcor and pxcor != min-pxcor and pycor != min-pycor and pycor != max-pycor]
  set open-patch one-of open-patches

  ; Reuven added the following "if" so that we can get through setup without a runtime error.
  if open-patch = nobody [
    user-message "No open patches found.  Exiting."
    stop
  ]

  setxy ([ pxcor ] of open-patch) ([ pycor ] of open-patch)
  set heading random 360
  fd random-float .4
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wall penetration error handling procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; if particles actually end up within the wall

to remove-from-walls
  let this-wall walls-here with [ not hidden? ]

  if count this-wall != 0 [
    let available-patches patches with [ not any? walls-here ]
    let closest-patch nobody
    if (any? available-patches) [
      set closest-patch min-one-of available-patches [ distance myself ]
      set heading towards closest-patch
      setxy ([ pxcor ] of closest-patch)  ([ pycor ] of closest-patch)
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GRAPHS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to do-plotting
   update-plots

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;REPORTERS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report speed-from-energy
  report sqrt (2 * energy / mass)
end

to-report energy-from-speed
  report (mass * speed * speed / 2)
end

to-report limited-particle-energy
  let limited-energy energy
  if limited-energy > max-particle-energy [ set limited-energy max-particle-energy ]
  if limited-energy < min-particle-energy [ set limited-energy min-particle-energy ]
  report limited-energy
end


; Copyright 2006 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
350
90
962
515
-1
-1
17
1
10
1
1
1
0
1
1
1
-15
20
-8
16
1
1
1
ticks
30

BUTTON
140
10
240
50
go/pause
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
35
10
137
50
setup/reset
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
300
10
535
43
initial-#-small-food-particles
initial-#-small-food-particles
0
200
100
1
1
NIL
HORIZONTAL

SLIDER
25
55
260
88
villi-height
villi-height
0
10
0
1
1
NIL
HORIZONTAL

SLIDER
785
10
970
43
end-simulation-at
end-simulation-at
0
24
20
1
1
hrs
HORIZONTAL

MONITOR
785
45
970
90
simulated # hrs.
floor ticks
17
1
11

MONITOR
540
45
775
90
particles absorbed into blood
count particles with [absorbed?]
17
1
11

MONITOR
300
45
535
90
particles still in small intestine
count particles with [not absorbed?]
17
1
11

MONITOR
25
140
260
185
% particles absorbed Into the blood
100 * count particles with [absorbed?] / count particles
1
1
11

SLIDER
540
10
775
43
initial-#-large-food-particles
initial-#-large-food-particles
0
100
10
1
1
NIL
HORIZONTAL

PLOT
5
200
345
520
% of food absorbed into blood vs. not
time
percentage %
0
10
0
100
true
true
"" ""
PENS
"in intestine" 1 0 -7500403 true "" "if any? particles [plotxy ticks  (100 * count particles with [not absorbed?] / count particles)]"
"in blood" 1 0 -2674135 true "" "if any? particles [plotxy ticks (100 * count particles with [absorbed?] / count particles)]"

CHOOSER
25
90
262
135
visualize-food-in-blood-flow-as
visualize-food-in-blood-flow-as
"circulating around unused" "going someplace else and used"
1
@#$#@#$#@
## WHAT IS IT?
This model explores the relationship between the amount of surface area in the small intestine and the rate at which it absorbs food particle into the circulatory system. 

The model allows the user to vary the height/length of villi on the small intestine wall, thereby changing the amount of potential surface area that food particles traveling past this surface can interact with.  

This model is part of the OpenSciEd curriculum for Middle School: http://www.openscied.org/  It is used in lesson 8 of unit 7.3 of that series.


## HOW IT WORKS

In this model, food particles tend to flow from right to left, representing the movement of molecules through the small intestine as if they are suspended in a liquid. Particles wander some too in that liquid.  If a particle reaches the left or right side of the world, they appear on the other side (the world wraps from left to right).  

When large food particles (each represented as a series three circles connected together in a line) run into the intestinal wall they bounce off it, since they are too large to pass through it.

The intestinal walls are composed of interconnected cells, which have small pores/opening/gates in them that are semi-permeable to small food molecules.

When smaller food particles (each represented as a single circle) run into the intestinal wall of the small intestine they have a chance that they may either bounce off of the wall or may pass through it.  They will do the later if they end up encountering a pore/opening/gate in the cell membranes that make up that surface of that cells that line the intestinal wall.  The probability of encountering such an opening during a collision with a wall and passing through it is determined by a global variable (permeability).  The current values for that variable is set to give a 50% chance of either outcome occurring.

Food molecules that pass through the small intestine wall, enter red patches on the other side of the \line of cells that make up the intestinal wall).  They then follow a path through the blood flowing from left to right in the model, until the reach the right side of world.  At that point they will either reappear on the left side of the model and continue recirculating through the blood until the model run is complete.  This will happen if the setting for VISUALIZE-BLOOD-FLOW-AS is set to "circulating around unused".  If that is variable is set to "going someplace else and used", then when a food molecule reaches the right side of the word it will be removed from the world.  This represents that the food molecule was used up somewhere else in the body (e.g. as fuel, building blocks for growth, or long-term storage) and taken out of the blood stream when it was. 


## HOW TO USE IT

VILLI-HEIGHT INITIAL-#-SMALL-FOOD-PARTICLES - is a slider that determines the number of small food particles put into  the digestive track when SETUP is pressed.  

INITIAL-#-LARGE-FOOD-PARTICLES - is slider that determines the number of large food particles put into the digestive track when SETUP is pressed.  

END-SIMULATION-AT is a slider that determines the point in time at which the simulation automatically ends.  This allows for comparing outcomes for different in initial conditions for similar lengths of experimental simulation runs. 

VILLI-HEIGHT - is a slider that controls the height/length of villi on the small intestine wall.  Changing the value of this will change amount of potential surface area of the intestinal wall that food particles traveling past it can interact with.  This can interactively be changed while the modeling in running (as GO/PAUSED is pressed) as well as before the model is initialized (when SETUP is pressed).

VISUALIZE-BLOOD-FLOW-AS - is a chooser that determines what happens to the small food molecules that are absorbed across the small intestinal wall. There are two settings for it, either "circulating around unused", or  "going someplace else and used" 

PARTICLES STILL IN THE SMALL INTESTINE - is a monitor that reports the total number of particles (small and large) that haven't crossed the cell membrane barrier.  These are all the particles that in the black patches of the world.

PARTICLES ABSORBED INTO THE BLOOD - is a monitor that reports the total number of particles  that have crossed the cell membrane barrier, or in the red patches (the blood), or that flowed through the blood and have been removed from the model when they reached the edge of the model.  

SIMULATED # HRS - is a monitor that reports the amount of simulated time that has elapsed.

% PARTICLES ABSORBED INTO THE BLOOD - is a monitor that reports the percentage of particles absorbed into the blood.  

% OF FOOD ABSORBED INTO OR NOT - is a graph that plots the percentage of particles absorbed into the blood over time and also plots the percentage of particles remaining unabsorbed over time (in the intestine).


## THINGS TO TRY

Experiment with how villi height affects how many small food particles are absorbed over time.  


## EXTENDING THE MODEL

The model could be extended to show gas exchange between blood and the lungs in the alveoli.


## CREDITS AND REFERENCES

Developed by Michael Novak. The model is part of the OpenSciEd Middle School curriculum.  See http://www.openscied.org/. 


## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. (2019). OpenSciEd Villi Food Absportion. http://www.openscied.org/ OpenSciEd Middle School Curriculum series. 

Please cite the NetLogo software itself as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## COPYRIGHT AND LICENSE

This model is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 License. It can run in a browser as an .html file without a local installation of NetLogo. To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.


NetLogo Modeling software is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Copyright 2006 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Commercial licenses for NetLogo are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

carbon
true
0
Circle -1184463 true false 68 83 134

carbon-activated
true
0
Circle -1184463 true false 68 83 134
Line -2674135 false 135 90 135 210

carbon2
true
0
Circle -955883 true false 30 45 210

cell
true
0
Polygon -2064490 true false 45 15 30 30 15 60 15 150 15 225 30 270 60 285 240 285 270 270 285 240 285 75 270 30 240 15 75 15
Rectangle -16777216 true false 0 150 15 195
Rectangle -16777216 true false 0 60 15 105
Rectangle -16777216 true false 105 0 150 15
Polygon -16777216 true false 285 285 270 270 225 285 240 300
Rectangle -16777216 true false 195 0 240 15
Rectangle -16777216 true false 285 105 300 150
Rectangle -16777216 true false 285 195 300 240
Polygon -16777216 true false 15 285 30 270 15 225 0 240
Polygon -16777216 true false 285 15 270 30 285 75 300 60
Rectangle -16777216 true false 60 285 105 300
Rectangle -16777216 true false 150 285 195 300
Polygon -16777216 true false 15 15 30 30 75 15 60 0
Circle -8630108 true false 165 60 88

cell2
true
0
Polygon -2064490 true false 45 15 30 30 15 60 15 150 15 240 15 255 60 285 240 285 270 285 285 240 285 60 285 45 240 15 60 15
Rectangle -16777216 true false 0 180 15 225
Rectangle -16777216 true false 0 90 15 135
Rectangle -16777216 true false 75 0 120 15
Rectangle -16777216 true false 165 0 210 15
Rectangle -16777216 true false 285 75 300 120
Rectangle -16777216 true false 285 165 300 210
Polygon -16777216 true false 300 30 285 45 240 15 255 0
Rectangle -16777216 true false 90 285 135 300
Circle -8630108 true false 135 105 88
Rectangle -16777216 true false 180 285 225 300
Polygon -16777216 true false 0 270 15 255 60 285 45 300
Polygon -16777216 true false 30 0 45 15 15 60 0 45
Polygon -16777216 true false 270 300 255 285 285 240 300 255

circle
true
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 16 16 270
Circle -16777216 true false 46 46 210

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

co2
true
0
Circle -13791810 true false 83 165 134
Circle -13791810 true false 83 0 134
Circle -1184463 true false 83 83 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

eraser
false
0
Rectangle -7500403 true true 0 0 300 300

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

heater-a
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -16777216 true false 90 90 210 210

heater-b
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -16777216 true false 30 30 135 135
Rectangle -16777216 true false 165 165 270 270

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

hex-valve
false
0
Rectangle -7500403 false true 0 0 300 300
Polygon -7500403 false true 105 60 45 150 105 240 195 240 255 150 195 60

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

large-molecule
true
0
Polygon -7500403 true true 150 174 150 174 135 189 135 204 150 219 165 204 165 189
Polygon -7500403 true true 149 130 149 130 134 145 134 160 149 175 164 160 164 145
Polygon -7500403 true true 148 83 148 83 133 98 133 113 148 128 163 113 163 98

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

nitrogen
true
0
Circle -10899396 true false 83 135 134
Circle -10899396 true false 83 45 134

outline
true
0
Circle -7500403 false true 0 0 300

oxygen
true
0
Circle -13791810 true false 83 135 134
Circle -13791810 true false 83 45 134

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

small-molecule
true
0
Polygon -7500403 true true 150 135 150 135 135 150 135 165 150 180 165 165 165 150

spray paint
false
0
Rectangle -7500403 false true 0 0 300 300
Circle -7500403 false true 75 75 150

square
false
0
Rectangle -7500403 true true 0 0 300 300

square 2
false
3
Rectangle -6459832 true true 0 -15 300 300

square 3
false
3
Rectangle -6459832 true true 0 -15 300 300
Rectangle -7500403 true false 0 285 300 300

square 4
false
3
Rectangle -6459832 true true 0 -15 300 300
Rectangle -7500403 true false 0 0 15 300

square 5
false
3
Rectangle -6459832 true true 0 -15 300 300
Rectangle -7500403 true false 0 0 15 300

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

valve-1
false
0
Rectangle -7500403 false true 0 0 300 300
Rectangle -7500403 false true 120 120 180 180

valve-2
false
0
Rectangle -7500403 false true 0 0 300 300
Rectangle -7500403 false true 60 120 120 180
Rectangle -7500403 false true 165 120 225 180

valve-hex
false
0
Rectangle -7500403 false true 0 0 300 300
Polygon -7500403 false true 105 60 45 150 105 240 195 240 255 150 195 60

valve-triangle
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -16777216 true false 150 45 30 240 270 240

valves
false
0
Rectangle -7500403 false true 0 0 300 300

wall
false
0
Rectangle -7500403 true true 0 0 300 300

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0
-0.2 0 0 1
0 1 1 0
0.2 0 0 1
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@

@#$#@#$#@
