part of observable_roles;

/**
 * Watches publishers for events they emit, then reacts to each event by invoking event handlers.
 *
 * Subscriber objects are added into publisher's `Pubslisher#observing_subscribers` List.
 * Every time such a publisher publishes an event it makes sure our subscriber
 * is notified - that is achieved by calling the `captureEvent()` method.
 *
 * `captureEvent()` in turn, doesn't autmoatically execute the event handler,
 * but simply adds the event to queue. This is because we want to process events
 * one by one and the order of executing the handlers may matter. After the event
 * is added into the queue, it calls `_releaseQueuedEvents()` which invokes event
 * handlers for each event in the queue until it ends. Thus, it may happen so that
 * some calls to `_releaseQueuedEvents()` may actually be for nothing, since event B
 * previously added to the queue was released by the call made to `_releaseQueuedEvents()`
 * while event A was captured. This an unlikely situation, though.
 *
 * More importantly, each subscriber has a listening lock. When it's on (set to `true`),
 * events are captured (added to the queue), but handlers for them are not yet invoked.
 * as soon as the value of the listening lock changes to `false`, events start being released
 * by calling `_releaseQueuedEvents()`. This may be very useful in certain cases when
 * you have to make sure event handlers are invoked only when an object reaches a certain state,
 * but no earlier (example: process clicks only when the page is loaded).
 */
abstract class Subscriber {

  /// A map of functions serving as event handlers.
  ///
  /// Those are invoked each time an event with the specified key is fired
  /// by one of the publishers this subscriber watches.
  Map event_handlers = {}; 

  // Whenever this one is set to true, we put events in a waiting queue
  // will put events in a queue and wait until it's true again -
  // then it's going to publish the event.
  bool _listening_lock = false;

  get listening_lock => _listening_lock;
  set listening_lock(lock) {
    _listening_lock = lock;
    if(lock == false) _releaseQueuedEvents();
  } 

  /// Keeps events that are currently on hold because of the publishers listening_lock 
  List events_queue = [];

  /**
   * Captures events but does not execute it.
   * 
   * Instead, adds event to a queue,
   * then unless listening_lock is on, releases all of the queued events with
   * _releaseQueuedEvents(). Really, if listening lock is off, it may be just
   * this one event in the queue, but we have to be sure.
   */
  captureEvent(name, publisher_roles, [data=null]) {
    events_queue.add({ 'name': name, 'publisher_roles': publisher_roles, 'data': data});
    if(listening_lock == false) _releaseQueuedEvents();
  }

  /**
   * Releases all the events that were previously queued due to listening lock.
   * 
   * It checks for the lock on each event release, so if while the loop is running
   * someone elsewhere sets the listening lock, it breaks the loop and returns.
   */
  _releaseQueuedEvents() {
    while(!events_queue.isEmpty && listening_lock == false) {
      var e = events_queue.removeAt(0);
      _handleEvent(_pickEvent(e['name'], e['publisher_roles']), e['data']);
    }
    _listening_lock = false;
  }

  _pickEvent(name, publisher_roles) {
    if(event_handlers[name] != null) {
      if(publisher_roles != null) {
        var picked_handler;
        publisher_roles.forEach((r) {
          if(event_handlers[name].keys.contains(r)) {
            picked_handler = event_handlers[name][r]; return;
          }
          else {
            var multirole_handlers = event_handlers[name].keys.toList();
            multirole_handlers.retainWhere((k) => k is List);
            multirole_handlers.forEach((list_of_keys) {
              if(publisher_roles.toSet().intersection(list_of_keys.toSet()).isNotEmpty)
                picked_handler = event_handlers[name][list_of_keys]; return;
            });
            if(picked_handler != null)
              return;
          }
        });
        if(picked_handler != null)
          return picked_handler;
      }
      if(event_handlers[name][#all] != null) {
        return event_handlers[name][#all];
      }
    }
  }

  /**
   * Invokes an assigned event handler for the event, passes itself to it. 
   */
  _handleEvent(e,[data=null]) {
    if(e != null && data != null)
      e(reflect(this).reflectee, data);
    else
      e(reflect(this).reflectee);
  }

}
