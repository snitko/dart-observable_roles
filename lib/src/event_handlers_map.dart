part of observable_roles;

/**
 * This class helps define/add/remove Event Handlers for Subscriber in a way that's
 * not completely ugly. Basically, event handlers is a 2-level Map, but it's difficult to manage it in a
 * reasonable way without resorting to traversing it in some ugly manner.
 *
 * Initially, a map may be passed to the constructor, but the idea is that actual users will use
 * it inside their classes constructors like this:
 *
 *   class MyComponent implements Subscriber {
 *
 *     var event_handlers = new EventHandlersMap();
 *
 *     MyComponent() {
 *       event_handlers.add(...);
 *       event_handlers.add_for_role('button', ...);
 *       event_handlers.add_for_event('click', ...);
 *     }
 *
 *   }
 *
 * For convenience, it implements Map's [] operator, although it doesn't implement all Map interface.
 * Due to language constraints, it made no sense to inherit from Map.
 *  
**/ 
class EventHandlersMap {

  Map _map;

  operator [](i) => _map[i]; 

  EventHandlersMap([source_map=null]) {
    if(source_map is Map)
      _map = source_map;
    else
      _map = {};
  }

  add({event: null, role: null, handler: null}) {
    if(!_map.containsKey(event))
      _map[event] = {};
    _map[event][role] = handler;
  }

  add_for_role(String role, Map handlers) {
    handlers.forEach((k,v) => this.add(event: k, role: role, handler: v));
  }

  add_for_event(String event, Map handlers) {
    handlers.forEach((k,v) => this.add(event: event, role: k, handler: v));
  }

  remove({event: null, role: null}) {
    if(_map.containsKey(event) && _map[event].containsKey(role))
      _map[event].remove(role);
    if(_map[event].length == 0)
      _map.remove(event);
  }

  remove_for_role(String role, List handlers) {
    handlers.forEach((i) => this.remove(event: i, role: role));
  }

  remove_for_event(String event, List handlers) {
    handlers.forEach((i) => this.remove(event: event, role: i));
  }

}
