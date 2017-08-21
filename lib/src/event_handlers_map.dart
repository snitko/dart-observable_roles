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
  get map => _map;

  operator [](i) => _map[i]; 

  EventHandlersMap([source_map=null]) {
    _map = {};
    if(source_map is Map) {
      source_map.forEach((event,events_map) {
        events_map.forEach((role,handlers) {
          if(!(handlers is List))
            handlers = [handlers];
          handlers.forEach((handler) {
            this.add(event: event, role: role, handler: handler);
          });
        });
      });
    }
  }

  /** Adds a an event handler for one or more roles (`roles` can be a List of roles too).
   * 
   * The `option` argument here doesn't mean anything. It's reserved for other libraries
   * using this functionality to pass something important to them to be stored
   * along with each particular handler.
   */
  add({event: null, role: #self, handler: null, options: null}) {
    if(event is String)
      event = [event];
    
    event.forEach((e) {
      if(!_map.containsKey(e))
        _map[e] = {};

      // Events may have multiple event handlers defined for them,
      // thus there's actually a list of handlers to be invoked.
      if(!_map[e].containsKey(role))
        _map[e][role] = [];
      _map[e][role].add({ "handler": handler, "options": options });
    });
  }

  addForRole(String role, Map handlers, { options: null }) {
    handlers.forEach((k,v) => this.add(event: k, role: role, handler: v, options: options));
  }

  addForEvent(event, Map handlers, { options: null }) {
    handlers.forEach((k,v) => this.add(event: event, role: k, handler: v, options: options));
  }

  remove({event: null, role: null}) {
    if(event is String)
      event = [event];
    event.forEach((e) {
      if(_map.containsKey(e) && _map[e].containsKey(role))
        _map[e].remove(role);
      if(_map[e].length == 0)
        _map.remove(e);
    });
  }

  removeForRole(String role, List handlers) {
    handlers.forEach((i) => this.remove(event: i, role: role));
  }

  removeForEvent(String event, List handlers) {
    handlers.forEach((i) => this.remove(event: event, role: i));
  }

  hasHandlerFor({ role, String event }) {
    if(_map.keys.contains(event)) {
      var has_role = false;
      _map[event].keys.forEach((k) {
        if(!(role is List))
          role = [role];
        role.forEach((r) {
          if((!(k is List) && k == r) || (k is List && k.contains(r)))
            has_role = true;
        });
      });
      return has_role;
    }
    return false;
  }

}
