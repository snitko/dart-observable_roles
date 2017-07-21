part of observable_roles;

/**
 * Publishes events that are picked by its Subscribers, that in turn invoke
 * event handlers on them.
 *
 * A Publisher has a role and its observing subscribers. To trigger an event,
 * one calls a `publishEvent()` method from inside or outside of the object,
 * passing it event name and data. This method, in turn, calls a `Subscriber#captureEvent()`
 * on each of the observing subscribers. Those subscribers then decide what to do with the event
 * (which event handler, if any, to invoke) based on the role of the publisher.
 */
abstract class Publisher {

  /// All subscribers who listen to this publisher events
  List observing_subscribers = [];

  /// The role of this publisher, which is later passed to
  /// the `Subscriber#captureEvent()` method. It essentially defines
  /// which handler (if any) in the subscriber is going to be invoked
  /// for the event.
  List<String> roles = [];

  /**
   * Adds new subscriber to the list of subscribers, who observe this publisher.
   */
  addObservingSubscriber(Subscriber s) {
    if(s is Subscriber)
      observing_subscribers.add(s);                 
    else
      throw new Exception("Can't add `${s}` to subscriber's list of ${this}, because it doesn't implement Subscriber interface.");
  }

  /**
   * Removes a subscriber from the list of subscribers, who observe this publisher.
   */
  removeObservingSubscriber(Subscriber s) {
    observing_subscribers.remove(s);
  }

  /**
   * Publishes an event: notifies all observing subscribers of it.
   * 
   * For each subscriber in the list of observing subscribers,
   * calls a `Subscriber#captureEvent()` method, passing in
   * the name of the event, prefixed by the role of this publisher.
   */
  publishEvent(event_name, [data=null]) {

    // if data is null, we're sending the object itself as data.
    // This is the default behavior for children components in Dartifact,
    // which, when notifying their parents about their events, send a reference
    // to themselves.
    if(data==null) { data = reflect(this).reflectee; }
    
    // A shadow copy is used, because each subscriber may want to remove itself from the
    // observing list of the publisher while processing an event.
    // And that would cause a modyfing iterable list error.
    var observing_subscribers_shadow = [];
    observing_subscribers.forEach((s) {
      observing_subscribers_shadow.add(s);
    });
    
    observing_subscribers_shadow.forEach((s) {
      s.captureEvent(event_name, this.roles, data: data);
    });

  }

}
