import "package:test/test.dart";
import 'dart:mirrors';
import '../lib/observable_roles.dart';

class DummyPublisher extends Object with Publisher {}

class DummySubscriber extends Object with Subscriber, Publisher {
  
  var event_handlers_called = [];

  Map event_handlers = {
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
    
    /*test('queues events when it is locked', () {*/
      /*publisher.addObservingSubscriber(subscriber);*/

      /*subscriber.listening_lock = true;*/
      /*publisher.publishEvent('queued_event');*/
      /*publisher.publishEvent('queued_event');*/
      /*expect(subscriber.events_queue.length, equals(2));*/
      /*expect(subscriber.event_handlers_called.length, equals(0));*/
      /*expect(subscriber.event_handlers_called.contains('#queued_event'), isFalse);*/

      /*subscriber.listening_lock = false;*/
      /*expect(subscriber.events_queue.length, equals(0));*/
      /*expect(subscriber.event_handlers_called.length, equals(2));*/
      /*expect(subscriber.event_handlers_called.contains('#queued_event'), isTrue);*/

    /*});*/

  });

}
