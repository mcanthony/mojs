Tween   = window.mojs.Tween
easing   = window.mojs.easing
h        = window.mojs.h
tweener  = window.mojs.tweener

describe 'Tween ->', ->
  describe 'init ->', ->
    it 'calc totalDuration and totalTime', ->
      t = new Tween duration: 1000, delay: 100
      expect(t.props.totalDuration).toBe  1000
      expect(t.props.totalTime).toBe      1100
      t = new Tween duration: 1000, delay: 100, repeat: 5
      expect(t.props.totalDuration).toBe  6500
      expect(t.props.totalTime).toBe      6600
  describe 'defaults ->', ->
    it 'should have vars', ->
      t = new Tween
      expect(t.props) .toBeDefined()
      expect(t.h)     .toBeDefined()
      expect(t.progress).toBe 0
    it 'should have defaults', ->
      t = new Tween
      expect(t.defaults.duration).toBe  600
      expect(t.defaults.delay).toBe     0
      expect(t.defaults.yoyo).toBe      false
      expect(t.defaults.isChained).toBe false
    it 'should extend defaults to options', ->
      t = new Tween duration: 1000
      expect(t.o.duration).toBe   1000
      expect(t.o.delay).toBe      0

  describe 'isChained option ->', ->
    it 'should recieve isChained option', ->
      t = new Tween
        duration: 1000, isChained: true
      expect(t.o.isChained).toBe  true
    it 'should fallback to default isChained option', ->
      t = new Tween
        duration: 1000
      expect(t.o.isChained).toBe false

  describe 'start ->', ->
    it 'should calculate start time', ->
      t = new Tween(duration: 1000, delay: 500).start()
      now = performance.now() + 500
      expect(t.props.startTime).not.toBeGreaterThan now
      expect(t.props.startTime).toBeGreaterThan     now-50
    it 'should recieve the start time', ->
      t = new Tween(duration: 1000).start 1
      expect(t.props.startTime).toBe 1
    it 'should calculate end time', ->
      t = new Tween(duration: 1000, delay: 500).start()
      expect(t.props.endTime).toBe t.props.startTime + 1000
    it 'should calculate end time if repeat', ->
      t = new Tween(duration: 1000, delay: 500, repeat: 2).start()
      time = t.props.startTime+(3*(1000+500))-500
      expect(t.props.endTime).toBeCloseTo time, 5
    it 'should restart flags', ->
      t = new Tween(duration: 20, repeat: 2).start()
      t.update t.props.startTime + 10
      t.update t.props.startTime + 60
      expect(t.isCompleted).toBe true
      expect(t.isStarted)  .toBe true
      t.start()
      expect(t.isCompleted).toBe false
      expect(t.isStarted)  .toBe false
  describe 'update method ->', ->
    it 'should update progress', ->
      t = new Tween(duration: 1000, delay: 500)
      t.start()
      time = t.props.startTime + 200
      t.update time
      expect(t.progress).toBe .2
    it 'should update progress with repeat', ->
      t = new Tween(duration: 1000, delay: 200, repeat: 2)
      t.start()
      t.update t.props.startTime + 1400
      expect(t.progress).toBeCloseTo .2
      t.update t.props.startTime + 2700
      expect(t.progress).toBeCloseTo .3
      t.update t.props.startTime + 3400
      expect(t.progress).toBe 1
    
    it 'should update progress to 1 if in delay gap and previous time value
        was smaller then the current one', ->
      t = new Tween(duration: 1000, delay: 200, repeat: 2)
      t.start()
      t.update t.props.startTime + 300
      t.update t.props.startTime + 1100
      expect(t.progress).toBe 1

    it 'should update progress to 1 if in delay gap and previous time value
        was bigger then the current one', ->
      t = new Tween(duration: 1000, delay: 200, repeat: 2)
      t.start()
      t.update t.props.startTime + 1300
      t.update t.props.startTime + 1100
      expect(t.progress).toBe 0


    it 'should update progress to 1 on the end', ->
      t = new Tween(duration: 1000, delay: 200, repeat: 2)
      t.start()
      t.update t.props.startTime + 1000
      expect(t.progress).toBeCloseTo 1, 5
    it 'should return true on the end', ->
      t = new Tween(duration: 1000, delay: 200)
      t.start()
      returnValue = t.update t.props.startTime + 1000
      expect(t.progress).toBeCloseTo 1, 5
      expect(t.isCompleted).toBe true
      expect(returnValue).toBe true
    it 'should not call update method if timeline isnt active "-"', ->
      t = new Tween(duration: 1000, onUpdate:->)
      t.start()
      spyOn t, 'onUpdate'
      t.update(performance.now() - 500)
      expect(t.onUpdate).not.toHaveBeenCalled()
    it 'should not call update method if timeline isnt active "+"', ->
      cnt = 0
      t = new Tween(duration: 1000, onUpdate:-> cnt++ )
      t.start(); t.update(performance.now() + 1500)
      expect(cnt).toBe 1
    it 'should set Tween to the end if Tween ended', ->
      t = new Tween(duration: 1000, delay: 500)
      t.start()
      t.update t.props.startTime + 1200
      expect(t.progress).toBe 1
  describe 'onUpdate callback ->', ->
    it 'should be defined', ->
      t = new Tween onUpdate: ->
      expect(t.o.onUpdate).toBeDefined()
    it 'should call onUpdate callback with the current progress', ->
      t = new Tween duration: 1000, easing: 'bounce.out', onUpdate: ->
      spyOn t, 'onUpdate'
      t.start()
      t.update t.props.startTime + 500
      expect(t.onUpdate).toHaveBeenCalledWith t.easedProgress
    it 'should have the right scope', ->
      isRightScope = false
      t = new Tween onUpdate:-> isRightScope = @ instanceof Tween
      t.start()
      t.update t.props.startTime + 200
      expect(isRightScope).toBe true

    it 'should be called just once on delay', ->
      t = new Tween delay: 200, repeat: 2, onUpdate:->
      spyOn(t, 'onUpdate').and.callThrough()
      t.start()
      t.update t.props.startTime + t.o.duration + 50
      t.update t.props.startTime + t.o.duration + 100
      t.update t.props.startTime + t.o.duration + 150
      expect(t.onUpdate.calls.count()).toBe 1

  describe 'onStart callback ->', ->
    it 'should be defined', ->
      t = new Tween(onStart: ->)
      t.start()
      expect(t.o.onStart).toBeDefined()
    it 'should call onStart callback', ->
      t = new Tween duration: 32, onStart:->
      t.start()
      spyOn(t.o, 'onStart')
      t.update t.props.startTime + 1
      expect(t.o.onStart).toHaveBeenCalled()
    it 'should be called just once', ->
      cnt = 0
      t = new Tween(duration: 32, onStart:-> cnt++).start()
      t.update(t.props.startTime + 1); t.update(t.props.startTime + 1)
      expect(cnt).toBe 1
    it 'should have the right scope', ->
      isRightScope = false
      t = new Tween(onStart:-> isRightScope = @ instanceof Tween)
      t.start()
      t.update t.props.startTime + 1
      expect(isRightScope).toBe true

  describe 'onReverseComplete callback ->', ->
    it 'should be defined', ->
      t = new Tween onReverseComplete: ->
      expect(t.o.onReverseComplete).toBeDefined()

    it 'should call onReverseComplete callback', ->
      t = new Tween(
        duration: 100
        onReverseComplete:->
      ).start()
      spyOn(t.o, 'onReverseComplete')
      t.update t.props.startTime + 55
      t.update t.props.startTime
      expect(t.o.onReverseComplete).toHaveBeenCalled()

    it 'should onReverseComplete only once', ->
      cnt = 0
      t = new Tween(
        duration: 100
        onReverseComplete:-> cnt++
      ).start()
      t.update t.props.startTime + 55
      t.update t.props.startTime
      t.update t.props.startTime - 20
      t.update t.props.startTime - 30
      expect(cnt).toBe 1
      expect(t.isOnReverseComplete).toBe true

    it 'should reset isOnReverseComplete flag', ->
      cnt = 0
      t = new Tween(
        duration: 100
        onReverseComplete:-> cnt++
      ).start()
      t.update t.props.startTime + 55
      t.update t.props.startTime
      t.update t.props.startTime - 20
      t.update t.props.startTime - 30
      t.update t.props.startTime + 1
      expect(t.isOnReverseComplete).toBe false

    it 'should reset isOnReverseComplete flag #2', ->
      cnt = 0
      t = new Tween(
        duration: 100
        onReverseComplete:-> cnt++
      ).start()
      t.update t.props.startTime + 55
      t.update t.props.startTime
      t.update t.props.startTime - 20
      t.update t.props.startTime - 30
      t.update t.props.endTime
      expect(t.isOnReverseComplete).toBe false

    it 'should have the right scope', ->
      isRightScope = null
      t = new Tween(
        duration: 100
        onReverseComplete:-> isRightScope = @ instanceof Tween
      ).start()
      t.update t.props.startTime + 55
      t.update t.props.startTime
      expect(isRightScope).toBe true

    it 'should setProgress to 0 if progress went before startTime', ->
      t = new Tween(
        duration: 100
        onReverseComplete:->
        onUpdate:->
      ).start()
      spyOn(t, 'onUpdate')
      t.update t.props.startTime + 55
      t.update t.props.startTime - 20
      expect(t.onUpdate).toHaveBeenCalledWith 0
      expect(t.progress).toBe 0

    it 'should not setProgress to 0 if timeline isChained', ->
      t = new Tween(
        duration: 100, isChained: true
        onReverseComplete:->
        onUpdate:->
      ).start()
      spyOn(t, 'onUpdate')
      t.update t.props.startTime + 55
      t.update t.props.startTime - 20
      expect(t.onUpdate).not.toHaveBeenCalledWith 0
      # expect(t.progress).toBe 0

  describe 'onComplete callback ->', ->
    it 'should be defined', ->
      t = new Tween onComplete: ->
      expect(t.o.onComplete).toBeDefined()
    it 'should call onComplete callback', ->
      t = new Tween(duration: 100, onComplete:->).start()
      spyOn(t.o, 'onComplete')
      t.update t.props.startTime + 101
      expect(t.o.onComplete).toHaveBeenCalled()
    it 'should be called just once', ->
      cnt = 0
      t = new Tween(duration: 32, onComplete:-> cnt++).start()
      t.update(t.props.startTime + 33)
      t.update(t.props.startTime + 33)
      expect(cnt).toBe 1

    it 'should reset isCompleted flag', ->
      t = new Tween(duration: 32, onComplete:->).start()
      t.update(t.props.startTime + 10)
      t.update(t.props.endTime)
      expect(t.isCompleted).toBe true
      t.update(t.props.startTime + 10)
      expect(t.isCompleted).toBe false

    it 'should have the right scope', ->
      isRightScope = false
      t = new Tween
        duration: 1, onComplete:-> isRightScope = @ instanceof Tween
      t.start().update t.props.startTime + 2
      expect(isRightScope).toBe true

    it 'should fire after the last onUpdate', (dfr)->
      proc = 0
      t = new Tween
        duration: 1,
        onUpdate:(p)->  proc = p
        onComplete:-> expect(proc).toBe(1); dfr()
      t.start().update t.props.startTime + 2
      

  describe 'onFirstUpdate callback ->', ->
    it 'should be defined', ->
      t = new Tween onFirstUpdate: ->
      expect(t.o.onFirstUpdate).toBeDefined()
    it 'should call onFirstUpdate callback', ->
      t = new Tween(duration: 100, onFirstUpdate:->).start()
      spyOn(t.o, 'onFirstUpdate')
      t.update t.props.startTime + 3
      expect(t.o.onFirstUpdate).toHaveBeenCalled()
    it 'should be called just once', ->
      cnt = 0
      t = new Tween(duration: 100, onFirstUpdate:-> cnt++ ).start()
      t.update t.props.startTime + 3
      t.update t.props.startTime + 3
      t.update t.props.startTime + 3
      expect(cnt).toBe 1
    it 'should have the right scope', ->
      isRightScope = false
      t = new Tween
        duration: 10, onFirstUpdate:-> isRightScope = @ instanceof Tween
      t.start().update t.props.startTime + 2
      expect(isRightScope).toBe true
    it 'should be called after progress went further the timeline', ->
      isRightScope = false
      t = new Tween
        duration: 10
        onFirstUpdate:->
      .start()
      t.update t.props.startTime + 1
      t.update t.props.startTime + 12
      spyOn(t.o, 'onFirstUpdate')
      t.update t.props.startTime + 9
      expect(t.o.onFirstUpdate).toHaveBeenCalled()

    it 'should be called before onStart callback', ->
      isOnStart = false; isOnStartCalled = true
      t = new Tween
        duration: 10
        onStart:-> isOnStart = true
        onFirstUpdate:-> isOnStartCalled = isOnStart
      .start()
      t.update t.props.startTime + 1
      expect(isOnStartCalled).toBe false

    it 'should be called after progress went before the timeline', ->
      isRightScope = false
      t = new Tween
        duration: 10
        onFirstUpdate:->
      .start()
      t.update t.props.startTime + 1
      t.update t.props.startTime + -1
      spyOn(t.o, 'onFirstUpdate')
      t.update t.props.startTime + 2
      expect(t.o.onFirstUpdate).toHaveBeenCalled()

  describe 'onFirstUpdateBackward callback ->', ->
    it 'should be defined', ->
      t = new Tween onFirstUpdateBackward: ->
      expect(t.o.onFirstUpdateBackward).toBeDefined()
    it 'should be called only on backward progress', ->
      isRightScope = false
      t = new Tween
        duration: 100
        onFirstUpdateBackward:->
      .start()
      t.update t.props.startTime + 500
      spyOn(t.o, 'onFirstUpdateBackward')
      t.update t.props.startTime + 40
      expect(t.o.onFirstUpdateBackward).toHaveBeenCalled()
    it 'should be called just once', ->
      cnt = 0
      t = new Tween(duration: 100, onFirstUpdateBackward:-> cnt++ ).start()
      t.prevTime = t.props.startTime + 103
      t.update t.props.startTime + 90
      t.update t.props.startTime + 80
      t.update t.props.startTime + 70
      expect(cnt).toBe 1
    it 'should have the right scope', ->
      isRightScope = false
      t = new Tween
        duration: 10
        onFirstUpdateBackward:-> isRightScope = @ instanceof Tween
      t.start()
      t.update t.props.startTime + 12
      t.update t.props.startTime + 9
      expect(isRightScope).toBe true
    it 'should be called after progress went further the timeline', ->
      t = new Tween(duration: 10, onFirstUpdateBackward: ->)
        .start()
      t.prevTime = t.props.startTime + 11
      t.update t.props.startTime + 9
      t.update t.props.startTime + 12
      spyOn(t.o, 'onFirstUpdateBackward')
      t.update t.props.startTime + 9
      expect(t.o.onFirstUpdateBackward).toHaveBeenCalled()
    it 'should not be called at the start', ->
      t = new Tween(duration: 10, onFirstUpdateBackward: ->)
        .start()
      spyOn(t.o, 'onFirstUpdateBackward')
      t.update t.props.startTime + 1
      expect(t.o.onFirstUpdateBackward).not.toHaveBeenCalled()
    it 'should be called even if new time is less then start time', ->
      t = new Tween
        duration: 100
        onFirstUpdateBackward:->
      .start()
      t.update t.props.startTime + 500
      spyOn(t.o, 'onFirstUpdateBackward')
      t.update t.props.startTime - 40
      expect(t.o.onFirstUpdateBackward).toHaveBeenCalled()
    it 'should be called ONCE if new time is less then start time', ->
      cnt = 0
      t = new Tween
        duration: 100
        onFirstUpdateBackward:-> cnt++
        
      .start()
      t.update t.props.startTime + 500
      t.update t.props.startTime - 40
      t.update t.props.startTime - 100
      expect(cnt).toBe 1

  describe 'yoyo option ->', ->
    it 'should recieve yoyo option', ->
      t = new Tween yoyo: true
      expect(t.o.yoyo).toBe true
    it 'should toggle the progress direction on repeat', ->
      t = new Tween(repeat: 2, duration: 10, yoyo: true).start()
      time = t.props.startTime
      t.update(time+1);   expect(t.progress).toBe .1
      t.update(time+5);   expect(t.progress).toBe .5
      t.update(time+10);  expect(t.progress).toBe 1

      t.update(time+11);  expect(t.progress).toBe .9
      t.update(time+15);  expect(t.progress).toBe .5
      t.update(time+19);  expect(parseFloat t.progress.toFixed(1)).toBe .1

      t.update(time+20);  expect(t.progress).toBe 0
      t.update(time+21);  expect(t.progress).toBe .1
      t.update(time+25);  expect(t.progress).toBe .5
      t.update(time+29);  expect(t.progress).toBe .9
      t.update(time+30);  expect(t.progress).toBe 1
      expect(t.isCompleted).toBe true

  describe 'easing ->', ->
    it 'should parse easing string', ->
      t = new Tween(easing: 'Linear.None')
      expect(typeof t.props.easing).toBe 'function'
    it 'should parse standart easing', ->
      t = new Tween(easing: 'Sin.Out', duration: 100)
      t.start(); t.update(t.props.startTime + 50)
      expect(t.easedProgress).toBe easing.sin.out t.progress
    it 'should work with easing function', ->
      easings = one: -> a = 1
      t = new Tween(easing: easings.one)
      expect(t.props.easing.toString()).toBe easings.one.toString()
    it 'should work with easing function', (dfr)->
      easings = one:(k)-> k
      spyOn easings, 'one'
      t = new Tween(easing: easings.one)
      t.start(); t.update t.props.startTime + 40
      setTimeout (-> expect(easings.one).toHaveBeenCalled(); dfr()), 50
  describe 'setProc method ->', ->
    it 'should set the current progress', ->
      t = new Tween(easing: 'Bounce.Out')
      t.setProc .75
      expect(t.progress).toBe .75
      expect(t.easedProgress.toFixed(2)).toBe '0.97'
    it 'should set new timeline options', ->
      t = new Tween duration: 100, delay: 0
      t.setProp duration: 1000, delay: 200
      expect(t.o.duration).toBe 1000
      expect(t.o.delay).toBe    200
    it 'should work with arguments', ->
      t = new Tween duration: 100
      t.setProp 'duration', 1000
      expect(t.o.duration).toBe 1000
    it 'should call calcDimentions method', ->
      t = new Tween duration: 100
      spyOn t, 'calcDimentions'
      t.setProp 'duration', 1000
      expect(t.calcDimentions).toHaveBeenCalled()
    it 'should update the totalTime', ->
      t = new Tween duration: 100
      t.setProp 'duration', 1000
      expect(t.props.totalTime).toBe 1000
  describe 'parseEasing method ->', ->
    it 'should parse function easing', ->
      t = new Tween duration: 100
      fun = ->
      expect(t.parseEasing(fun)).toBe fun
      expect(typeof t.parseEasing(fun)).toBe 'function'
    describe 'easing name option ->', ->
      it 'should parse string easing', ->
        t = new Tween duration: 100
        expect(typeof t.parseEasing('cubic.in')).toBe 'function'
      # it 'should call h.splitEasing method', ->
      #   t = new Tween duration: 100
      #   spyOn h, 'splitEasing'
      #   t.parseEasing('cubic.in')
      #   expect(h.splitEasing).toHaveBeenCalled()
    describe 'SVG path option ->', ->
      it 'should parse SVG path easing', ->
        t = new Tween duration: 100
        expect(typeof t.parseEasing('M0,100 L100,0')).toBe 'function'
      it 'should call easing.path method', ->
        t = new Tween duration: 100
        spyOn window.mojs.easing, 'path'
        t.parseEasing('M0,100 L100,0')
        expect(window.mojs.easing.path).toHaveBeenCalled()
    describe 'bezier option ->', ->
      it 'should parse bezier easing', ->
        t = new Tween duration: 100
        expect(typeof t.parseEasing([0.42,0,1,1])).toBe 'function'
      it 'should call bezier method', ->
        t = new Tween duration: 100
        spyOn window.mojs.easing, 'bezier'
        t.parseEasing([0.42,0,1,1])
        expect(window.mojs.easing.bezier).toHaveBeenCalled()

  describe 'splitEasing method', ->
    t = new Tween duration: 100
    it 'should split easing string to array',->
      expect(t.splitEasing('Linear.None')[0]).toBe 'linear'
      expect(t.splitEasing('Linear.None')[1]).toBe 'none'
    it 'should return default easing Linear.None if argument is bad', ->
      expect(t.splitEasing(4)[0]).toBe 'linear'
      expect(t.splitEasing(4)[1]).toBe 'none'
    it 'should return default easing Linear.None if argument is bad #2', ->
      expect(t.splitEasing('')[0]).toBe 'linear'
      expect(t.splitEasing('')[1]).toBe 'none'
    it 'should return default easing Linear.None if argument is bad #3', ->
      expect(t.splitEasing('Linear..None')[0]).toBe 'linear'
      expect(t.splitEasing('Linear..None')[1]).toBe 'none'
    it 'should work with lovercase easing', ->
      expect(t.splitEasing('linear..none')[0]).toBe 'linear'
      expect(t.splitEasing('linear..none')[1]).toBe 'none'
    it 'should work with function easing', ->
      easing = -> console.log 'function'
      expect(t.splitEasing(easing)+'').toBe easing+''

  describe 'run method ->', ->
    describe 'start method ->', ->
      it 'should get the start time',->
        t = new Tween
        t.run()
        expect(t.props.startTime).toBeDefined()
        expect(t.props.endTime).toBe t.props.startTime + t.props.totalTime
      it 'should call the setStartTime method',->
        t = new Tween
        spyOn t, 'start'
        time = 0
        t.run time
        expect(t.start).toHaveBeenCalledWith time
      it 'should add itself to tweener',->
        t = new Tween
        spyOn tweener, 'add'
        t.run()
        expect(tweener.add).toHaveBeenCalled()
      it 'should not add itself to tweener if time was passed',->
        t = new Tween
        spyOn tweener, 'add'
        t.run 10239123
        expect(tweener.add).not.toHaveBeenCalled()

  describe '_removeFromTweener method ->', ->
    it 'should call tweener.remove method with self',->
      tweener.removeAll()
      timeline = new Tween duration: 2000
      timeline.run()
      timeline._removeFromTweener()
      expect(tweener.tweens.length).toBe 0

  describe 'stop method', ->
    it 'should call r_emoveFromTweener method with self',->
      tweener.removeAll()
      timeline = new Tween duration: 2000
      timeline.run()
      spyOn timeline, '_removeFromTweener'
      timeline.stop()
      expect(timeline._removeFromTweener).toHaveBeenCalled()
    it 'should reset progress to 0',->
      tweener.removeAll()
      timeline = new Tween duration: 2000
      timeline.run()
      spyOn timeline, 'setProc'
      timeline.stop()
      expect(timeline.setProc).toHaveBeenCalledWith 0
    # it 'should set state to "stop"',->
    #   tweener.tweens = []
    #   t = new Tween
    #   timeline = new Tween duration: 2000
    #   t.add(timeline); t.start(); t.stop()
    #   expect(t.state).toBe 'stop'

  describe 'pause method ->', ->
    it 'should call t.remove method with self',->
      tweener.removeAll()
      timeline = new Tween duration: 2000
      timeline.run()
      spyOn timeline, '_removeFromTweener'
      timeline.pause()
      expect(timeline._removeFromTweener).toHaveBeenCalled()
    # it 'should set state to "pause"',->
    #   tweener.tweens = []
    #   t = new Tween
    #   timeline = new Tween duration: 2000
    #   t.add(timeline); t.start(); t.pause()
    #   expect(t.state).toBe 'pause'




