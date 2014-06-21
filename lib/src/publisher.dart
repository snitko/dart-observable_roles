part of observable_roles;

abstract class Publisher {

  List   observing_subscribers = []  ;
  String role                  = null;

  addObservingSubscriber(s) {
    if(s is Subscriber)
      observing_subscribers.add(s);                 
    else
      throw new Exception("Can't add `${s}` to subscriber's list of ${this}, because it doesn't implement Subscriber interface.");
  }

  removeObservingSubscriber(s) {
    observing_subscribers.remove(s);
  }

  publishEvent(event_name, [data=null]) {

    if(data==null) { data = reflect(this).reflectee; }
    
    var caller_name;
    if(role != null)
      caller_name = role;
    else
      caller_name = MirrorSystem.getName(reflect(this).type.simpleName);

    // A shadow copy is used, because each subscriber may want to remove itself from the
    // observing list of the publisher while processing an event.
    // And that would cause a modyfing iterable list error.
    var observing_subscribers_shadow = [];
    observing_subscribers.forEach((s) {
      observing_subscribers_shadow.add(s);
    });
    
    observing_subscribers_shadow.forEach((s) {
      s.captureEvent("${caller_name}.$event_name", data);
    });

  }

}
