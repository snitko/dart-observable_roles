import "package:test/test.dart";
import 'dart:mirrors';
import '../lib/observable_roles.dart';

var original_event_handlers = {
  'updated' : {
    #self              : (self, p) => self.event_handlers_called.add('#updated event for self'),
    #all               : (self, p) => self.event_handlers_called.add('#updated event for all roles'),
    'dummy'            : (self, p) => self.event_handlers_called.add('#updated event for dummy'),
    ['role1', 'role2'] : (self, p) => self.event_handlers_called.add('an #updated event for two roles')
  },
  'queued_event' : {
    #all : (self, p) => self.event_handlers_called.add('#queued_event for all children'),
  }
};

class DummyPublisher extends Object with Publisher {}
class DummySubscriber extends Object with Subscriber, Publisher {
  var event_handlers_called = [];
  var event_handlers = new EventHandlersMap(original_event_handlers);

  DummySubscriber() {
    event_handlers.add(
      role: 'role7', event: 'deleted',
      handler: (self, p) => self.event_handlers_called.add('a #deleted event for role7')
    );
    event_handlers.add(role: "role8", event: "deleted", handler: (self,p) => self.event_handlers_called.add('a #deleted #1 event for role8'));
    event_handlers.add(role: "role8", event: "deleted", handler: (self,p) => self.event_handlers_called.add('a #deleted #2 event for role8'));
  }

}

void main() {

  var publisher;
  var subscriber;

  setUp(() {
    publisher  = new DummyPublisher() ;
    subscriber = new DummySubscriber();
  });

  group('Publisher', () {

    test('publisher allows subscribers to be added into and removed from its list of subscribers', () {
      publisher.addObservingSubscriber(subscriber);
      expect(publisher.observing_subscribers.contains(subscriber), isTrue);
      publisher.removeObservingSubscriber(subscriber);
      expect(publisher.observing_subscribers.contains(subscriber), isFalse);
      expect(() => publisher.add('Not a subscriber'), throws);
    });

    test('publisher notifies all subscribers of a new event, subscribers react to events from publishers by running callbacks', () {
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('updated');
      expect(subscriber.event_handlers_called, contains('#updated event for all roles'));
    });

  });

  group('Subscriber', () {

    test('uses a particular role for handling the published event', () {
      publisher.roles = ['dummy'];
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('updated');
      expect(subscriber.event_handlers_called, contains('#updated event for dummy'));
    });
    
    test('queues events when it is locked', () {
      publisher.addObservingSubscriber(subscriber);

      subscriber.listening_lock = true;
      publisher.publishEvent('queued_event');
      publisher.publishEvent('queued_event');
      expect(subscriber.events_queue.length, equals(2));
      expect(subscriber.event_handlers_called.length, equals(0));
      expect(subscriber.event_handlers_called, isEmpty);

      subscriber.listening_lock = false;
      expect(subscriber.events_queue.length, equals(0));
      expect(subscriber.event_handlers_called.length, equals(2));
      expect(subscriber.event_handlers_called, contains('#queued_event for all children'));

    });

    test('handles events from two different children with two different roles using the same handler', () {
      var publisher1 = new DummyPublisher();
      var publisher2 = new DummyPublisher();
      publisher1.roles = ['role1'];
      publisher2.roles = ['role2'];
      publisher1.addObservingSubscriber(subscriber);
      publisher2.addObservingSubscriber(subscriber);
      publisher1.publishEvent('updated');
      publisher2.publishEvent('updated');
      expect(subscriber.event_handlers_called.length, 2);
      expect(subscriber.event_handlers_called, contains('an #updated event for two roles'));
    });

    test('handlers added with EventHandlersMap methods are invoked correctly', () {
      publisher.roles = ['role7'];
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('deleted');
      expect(subscriber.event_handlers_called, contains('a #deleted event for role7'));
    });

    test("ignores an event if there's no handler for it", () {
      publisher.addObservingSubscriber(subscriber);
      publisher.roles = ['dummy'];
      expect(() => publisher.publishEvent('non-existent-event'), returnsNormally);
      publisher.roles = ['non-existent-role'];
      expect(() => publisher.publishEvent('non-existent-event'), returnsNormally);
    });

    test("allows to add multiple handlers for each event/role", () {
      publisher.roles = ['role8'];
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('deleted');
      expect(subscriber.event_handlers_called, contains('a #deleted #1 event for role8'));
      expect(subscriber.event_handlers_called, contains('a #deleted #2 event for role8'));
    });

  });

  group('EventHandlersMap', () {

    var event_handlers;

    setUp(() {
      event_handlers = new EventHandlersMap(original_event_handlers);
    });

    test('adds a single handler for role and event', () {
      event_handlers.add(role: 'role3', event: 'updated', handler: () => print("role3#updated"));
      expect(event_handlers["updated"]["role3"], isNotNull);
    });

    test('removes a single handler for role and event', () {
      event_handlers.remove(role: 'dummy', event: 'updated');
      expect(event_handlers["updated"]["dummy"], isNull);
    });

    test('adds and then removes multiple handlers for one role but many events', () {
      event_handlers.addForRole('role4', {
        'updated': () => print("role4#updated"),
        'saved':   () => print("role4#saved"),
      });
      expect(event_handlers["updated"]["role4"], isNotNull);
      expect(event_handlers["saved"]["role4"],   isNotNull);

      event_handlers.removeForRole('role4', ["updated", "saved"]);
      expect(event_handlers["updated"]["role4"], isNull);
      expect(event_handlers["saved"], isNull);
    });

    test('adds and then removes multiple handlers for one event but many roles', () {
      event_handlers.addForEvent('saved', {
        'role5': () => print("role5#saved"),
        'role6': () => print("role6#saved"),
      });
      expect(event_handlers["saved"]["role5"], isNotNull);
      expect(event_handlers["saved"]["role6"], isNotNull);

      event_handlers.removeForEvent('saved', ["role5", "role6"]);
      expect(event_handlers["saved"], isNull);
    });

    test("checks whether an event handler exists for the given role and event", () {
      expect(event_handlers.hasHandlerFor(role: 'role1', event: 'updated'), isTrue);
      expect(event_handlers.hasHandlerFor(role: 'role100', event: 'updated'), isFalse);
      expect(event_handlers.hasHandlerFor(role: #self, event: 'updated'), isTrue);
      expect(event_handlers.hasHandlerFor(role: #all, event: 'updated'), isTrue);
    });

    test("adds multiple identical handlers for multiple events", () {
      event_handlers.add(role: 'role3', event: ['updated', 'saved'], handler: () => print("role3#updated"));
      expect(event_handlers["updated"]["role3"], isNotNull);
      expect(event_handlers["saved"]["role3"], isNotNull);
    });

    test("strores options along with handlers", () {
      event_handlers.add(role: 'role3', event: ['updated', 'saved'], handler: () => print("role3#updated"), options: { "special_option": true });
      expect(event_handlers["updated"]["role3"][0]["options"]["special_option"], isTrue);
      expect(event_handlers["saved"]["role3"][0]["options"]["special_option"], isTrue);
    });

  });

}
