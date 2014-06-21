import '../lib/observable_roles.dart';

class MySubscriber extends Object with Subscriber {
  Map event_handlers = {
    'file_terminator.click'  : (self, data) => print("Deleting files"),
    'document_creator.click' : (self, data) => print("Creating a new document"),
    'motivator.click'        : (self, data) => print("Showing a motivational video"),
    'Button.click'           : (self, data) => print("A click event was triggered")
  };
}

class Button extends Object with Publisher {
  String role = null;  // default is null, you don't have to write it
  Button([this.role]); // Set the role while creating an object
}

main() {
  var red_button   = new Button('file_terminator');
  var green_button = new Button('document_creator');
  var blue_button  = new Button('motivator');

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
