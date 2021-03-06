Observable Roles
================
An implementation of the Observable pattern, on steroids and in Dart

Why? (a usecase)
----------------
We all know the observable pattern. Observer watches some object for events, when they happen - it invokes event handlers.
Turns out, this isn't enough for some cases.

Imagine you have three buttons: red, green and blue, each is represented by an Object, which is going to emit a 'click' event when
a button is clicked - we'll call that object Publisher. Suppose we have an object which listens to those events, let's call it Subscriber.
That is, we now have on subscriber, which is subscribed to events from three Publishers.

Obviously, our buttons serve different purposes in our app. The red one deletes files, the green one creates a new document and the blue one
really just shows our application user some random motivational video from YouTube. Of course, it is foolish to program those things into
the buttons themselves, so we leave this code for the Subscriber's event handlers. Buttons themselves, though, are essentially the same:
apart from the color, they seem to behave themselves in exactly the same manner: the show the text "Wait..." after they are clicked, impacted
while they are being clicked and they look flat when disabled. Still we may say their roles are somewhat different.

Here we come across an important, but really a very simple concept. Each publisher may be assigned a role (it's optional, though!). So when
an event happens, our Subscriber knows publisher with which role triggered the event. With that knowledge, we can now assign three different
event handlers.

Another important idea is the ability of any Subscriber to stay locked for a while. A so called listening lock may be set to `true`, in which case
any new event that is emmited by Publishers is captured, but the evend handler isn't invoked until the lock is set to `false` again. As an example of this idea
we may say that until a new document is created, we will not process user requests for deleting of any files.

Code example
------------

The following would be an example code implementing the scenario with the three buttons described above:

    import 'package:observable_roles';

Let's create a class that includes the Subscriber mixin and define event handlers in this class:

    class MySubscriber extends Object with Subscriber {
      var event_handlers = {
        'click' : {
          #all : (self, p) => print("A click event was triggered"),
          'file_terminator'  => print("Deleting files"),
          'document_creator' => print("Creating a new document"),
          'motivator'        => print("Showing a motivational video")
        }
      }; 
    }

Then we create a Button class. It'll be the same class for all buttons, because remeber - buttons
behave in the same way (color implementation is left out of it):

    class Button extends Object with Publisher {
      String roles = []
      Button([this.roles]); // Set roles when creating an object
    }

Now we create buttons, create a subscriber object and subscribe it to all the publishers
(that is, Buttons). Then check what happens when we trigger a `click` event:

    main() {
      var red_button   = new Button(['file_terminator']);
      var green_button = new Button(['document_creator']);
      var blue_button  = new Button(['motivator']);

      // This button doesn't have any role, so it will pass its
      // class name as a role later.
      var some_button  = new Button();

      var subscriber   = new MySubscriber();

      // Start listening for events from each button
      [red_button, green_button, blue_button, some_button].forEach((b) {
        b.addObservingSubscriber(subscriber);
      });

      red_button.publishEvent('click');   // => "Deleting files"
      green_button.publishEvent('click'); // => "Creating a new document"
      blue_button.publishEvent('click');  // => "Showing a motivational video"

      some_button.publishEvent('click');  // => "A click event was triggered"
    }

You're probably wondering if there's a simpler, nicer way of adding event_handlers to the Subscriber,
and the answer is, yes there is. Here's an alternative:

  class MyComponent implements Subscriber {
    var event_handlers = new EventHandlersMap();
    MyComponent() {
      event_handlers.add(event: ..., role: ..., handler: ...);
      event_handlers.add_for_role('button', [a Map, event: handler]);
      event_handlers.add_for_event('click', [a Map, role:  handler]);
    }
  }

Not that #add, #add_for_role and #add_for_event methods are called inside a constructor.
This is because event_handlers is an instance variable and can be accessed only within
object's context.
