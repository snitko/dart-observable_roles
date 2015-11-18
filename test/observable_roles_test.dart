import "package:test/test.dart";
import 'dart:mirrors';
import '../lib/observable_roles.dart';

class DummyPublisher extends Object with Publisher {}

class DummySubscriber extends Object with Subscriber, Publisher {
  
  var event_handlers_called = [];

  Map event_handlers = {
    'DummyPublisher.updated' : (self, p) => self.event_handlers_called.add('DummyPublisher.updated'),
    'dummy.updated'          : (self, p) => self.event_handlers_called.add('dummy.updated'),
    'propagator.updated'     : (self, p) => self.captureEvent('nativeUpdate'),
    'nativeUpdate'           : (self)    => self.event_handlers_called.add('updated'),
    'DummyPublisher.queued_event' : (self, p) => self.event_handlers_called.add('queued_event')
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
      expect(subscriber.event_handlers_called.contains('DummyPublisher.updated'), isTrue);
    });

    test('it uses role instead of class name when publishing the event', () {
      publisher.role = 'dummy';
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('updated');
      expect(subscriber.event_handlers_called.contains('dummy.updated'), isTrue);
    });

    test('propagates events that have no publisher (that is, they are triggered by the Subscriber itself)', () {
      publisher.role = 'propagator';
      publisher.addObservingSubscriber(subscriber);
      publisher.publishEvent('updated');
      expect(subscriber.event_handlers_called.contains('updated'), isTrue);
    });


  });

  group('Subscriber', () {
    
    test('queues events when it is locked', () {
      publisher.addObservingSubscriber(subscriber);

      subscriber.listening_lock = true;
      publisher.publishEvent('queued_event');
      publisher.publishEvent('queued_event');
      expect(subscriber.events_queue.length, equals(2));
      expect(subscriber.event_handlers_called.length, equals(0));
      expect(subscriber.event_handlers_called.contains('queued_event'), isFalse);

      subscriber.listening_lock = false;
      expect(subscriber.events_queue.length, equals(0));
      expect(subscriber.event_handlers_called.length, equals(2));
      expect(subscriber.event_handlers_called.contains('queued_event'), isTrue);

    });

  });

}
