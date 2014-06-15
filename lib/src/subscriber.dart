part of observable;

abstract class Subscriber {

  Map  event_handlers = {}; 

  // Whenever this one is set to true, we put events in a waiting queue
  // will put events in a queue and wait until it's true again -
  // then it's going to publish the event.
  bool _listening_lock = false;

  get listening_lock => _listening_lock;
  set listening_lock(lock) {
    _listening_lock = lock;
    if(lock == false) _releaseQueuedEvents();
  } 

  // Keeps events that are currently on hold because of the publishers_listening_lock 
  List events_queue = [];

  /* Captures events but does not execute it. Instead, adds event to a queue,
     then unless listening_lock is on, releases all of the queued events with
     _releaseQueuedEvents(). Really, if listening lock is off, it may be just
     this one event in the queue, but we have to be sure.
  */
  captureEvent(e, [data=null]) {
    events_queue.add({ 'name': e, 'data': data});
    if(listening_lock == false) _releaseQueuedEvents();
  }

  print_event(text, e, data) {
    if(e == 'exchange.orderbook_position_updated')
      print("${text}: ${data}");
  }

  /* Releases all the events that were previously queued due to listening lock.
    But it does check for the lock on each event release, so if while the loop is running
    someone elsewhere sets the listening lock, it breaks the loop and returns.
  */
  _releaseQueuedEvents() {
    while(!events_queue.isEmpty && listening_lock == false) {
      var e = events_queue.removeAt(0);
      _handleEvent(e['name'], e['data']);
    }
    _listening_lock = false;
  }

  _handleEvent(e, [data=null]) {

    if(event_handlers[e] != null) {
      if(data != null) {
        event_handlers[e](reflect(this).reflectee, data);
      } else {
        event_handlers[e](reflect(this).reflectee);
      }
    }

    // Subscriber can be a publisher at the same time
    // and have its own list of subscribers. A Russian Doll, if you may.
    // However, we only publish those events that directly belong to this subscriber,
    // that is:
    //    'DummyPublisher.update'
    //
    // won't be published, but this one will:
    //    'update'
    //
    // That way you can control perfectly what is being propagated. For instance,
    // you can set an event handler for 'DummyPublisher.update' which, in turn, triggers
    // a handler for 'update' event and this last one gets propagated.

    if(this is Publisher && !e.contains('.') && event_handlers.keys.contains(e))
      publishEvent(e);

  }

}
