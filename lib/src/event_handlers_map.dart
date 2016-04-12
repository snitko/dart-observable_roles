part of observable_roles;

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
