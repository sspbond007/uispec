


---


# UISpec #

UISpec is a Behavior Driven Development framework for the iPhone that provides a full automated testing solution that drives the actual iPhone UI. It is modeled after the very popular RSpec for Ruby, where you express executable examples of the expected behavior of your code.

Take for example a scenario where you are getting requirements from your customer on a new Employee Admin tool and you ask them to "describe" it.  They may say things like:

  * It should show a list of current users
  * It should add a user
  * It should not add an invalid user

In UISpec this is how we would express it using Objective-C:

```
@implementation DescribeEmployeeAdmin

-(void)itShouldAShowAListofCurrentUsers {
  ...
}

-(void)itShouldAddAUser {
  ...
}

-(void)itShouldNotAddAnInvalidUser {
  ...
}

@end
```

### Before and After ###
You can implement the methods "before" or "after" to define code that is run before or after each example in a description.  You can also implement the methods "beforeAll" or "afterAll" to define code that is run before all or after all examples in a description.

```
@implementation DescribeEmployeeAdmin
  
-(void)beforeAll {
  //This is run once and only once, before all of the examples
  //and before the "before" method.
}

-(void)before {
  //This is run before each example
}

-(void)itShouldAShowAListofCurrentUsers {
  ...
}

-(void)itShouldAddAUser {
  ...
}

-(void)itShouldNotAddAnInvalidUser {
  ...
}

-(void)after {
  //This is run after each example
}

-(void)afterAll {
  //This is run once and only once, after all of the examples
  //and after the "after" method.
}
  
@end
```

### Running Specs ###
Running your specs is as easy as calling `[UISpec runSpecs]`.  UISpec looks for all classes that conform to the protocol UISpec.  The protocol itself is used just as a marker and doesn't require any specific methods to be implemented.

```
@interface DescribeEmployeeAdmin : NSObject <UISpec> {
}
@end
```

On each class found, methods that have the prefix "it" are executed, and of course the beforeAll, before, afterAll, and after methods are run accordingly if they exist.

The big question though is **where do you include this call to run your specs?**  The recommended place is in your "main" method.  And if your iPhone app takes a little time to load you can include an optional delay time.

```
int main(int argc, char *argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  [UISpec runSpecsAfterDelay:3]; //give your app some time to load before running the specs

  int retVal = UIApplicationMain(argc, argv, nil, nil);
  [pool release];
  return retVal;
}
```


---


# UIQuery #
To make finding specific views in the iPhone UI easy, UISpec includes a very powerful view traversal DSL called UIQuery. Not only can you easily traverse the view heirarchy, you can also interact with the views you find.

A UIQuery object contains list of views with logic for traversing and filtering them, most calls return a new UIQuery object which allows for property and method chaining.  For example if you wanted to touch the cell in a table with the text "My Chicago Trip" in order to see it's details, you can do the following:

```
UIQuery *app = [UIQuery withApplication];  //this will get a handle to the UIApplication

[[app.tableViewCell.label text:@"My Chicago Trip"] touch];
```

### Traversal ###
When a traversal property is called on a UIQuery object, it tells UIQuery which direction to traverse the view hierarchy when collecting views into a new UIQuery object.  Since a UIQuery object itself contains a list of views, by default the **first** view is used as the starting point for the traversal.  If you want to traverse all the views in a UIQuery object call the property "all" beforehand.

  * find/descendant - collect views in the descendant direction
  * child - collect just the immediate child views
  * parent - collect parent views up to the UIApplication (top parent)

```
[app.find.tableViewCell touch];  //This will touch the first UITableViewCell it finds
[app.find.tableViewCell.all touch];  //This will touch the all the UITableViewCells it finds
[[app.find.label text:@"Order Detail"] parent].tableViewCell; //This will find the UITableViewCell that contains the label with the specified text
```

If you don't call a traversal method, UIQuery will automatically call find/descendant for you, so you can do the following instead:

```
[app.tableViewCell touch];  //This will touch the first UITableViewCell it finds
[app.tableViewCell.all touch];  //This will touch the all the UITableViewCells it finds
[[app.label text:@"Order Detail"] parent].tableViewCell; //This will find the UITableViewCell that contains the label with the specified text
```

### Filters ###
Filters are meant for further refinement of a traversal call, so you can get to the exact view you are looking for.  A filter is applied across the list of views in the current UIQuery object, returning a filtered list in a new UIQuery object.

  * view:classname - matches a view based on it's className
  * with property:value ... - matches a view based on it's properties and values
  * index:number - gets the view at the specified index in the UIQuery object's list of views
  * first - gets the first view in the UIQuery object's list of views
  * last - gets the last view in the UIQuery object's list of views

UIQuery also provides predefined properties for view class names that help making coding easier.  Just take off the "UI" and lowercase the first letter and you can quickly filter most UIView subclasses.  For example if you wanted to get the text from the last cell in a table, both of these would work:

```
NSString *cellText = [[[app view:@"UITableView"] view:@"UITableViewCell"].last text];
NSString *cellText = [app.tableView.tableViewCell.last text];
```

Using the method "with" is a very powerful way to dynamically match against almost any property on a UIView.  And you can match against as many properties as you need to all in one call.  For example:

```
[app.textField.with placeholder:@"Email"]; //looks for all UITextFields whose property "placeholder" contains the text Email
[app.tableViewCell.with text:@"Sabre" accessoryType:UITableViewCellAccessoryCheckmark]; //looks for every UITableViewCell whose property "text" contains Sabre and property "accessoryType" is set to UITableViewCellAccessoryCheckmark
```

In fact you don't even have to call "with", because by default if UIQuery or it's contained views don't respond to a message, then it just assumes you are doing a "with" property match.  So the following works too:

```
[app.textField placeholder:@"Email"]; //looks for all UITextFields whose property "placeholder" contains the text Email
[app.tableViewCell text:@"Sabre" accessoryType:UITableViewCellAccessoryCheckmark]; //looks for every UITableViewCell whose property "text" contains Sabre and property "accessoryType" is set to UITableViewCellAccessoryCheckmark
```

### View Interaction ###
As we all know a user interacts with the iPhone UI by touching it, so a UIQuery object provides a method called touch.  UIQuery also provides the methods show and flash which help with writing specs.  By default a view interaction call is applied to the **first** view in the UIQuery object.  If you want to apply the call to all the views contained in the UIQuery object, call the property "all" beforehand.

  * touch - simulates a user touch on the target view
  * show - reads all the properties on a view and logs them to the console
  * flash - flashes the view on iPhone so you can see where it's located

UIQuery also makes it easy to call existing methods or properties on the actual views you find.  If the method doesn't exist on a UIQuery object it will forward that call to the **first** view it contains.  To forward the call to all the contained views, call the property "all" beforehand.  For example take a UITextField, if you wanted to set it's text you would call it's api method setText:somevalue or set its property .text = somevalue.  With UIQuery it's as simple as doing either of the following:

```
[[app.textField placeholder:@"email"] setText:@"somevalue"];
//or by casting to a UITextField so you can access it's properties
UITextField *textField = [app.textField placeholder:@"email"];
textField.text = @"somevalue";
```

Dealing with some views can get quite complicated, so UIQuery provides several extension classes that provide simple methods that abstract a lot of verbose code.  Say you just wanted to scroll to the bottom of a UITableView.  Here is what the code would look like dealing directly with the UITableView:

```
UITableView *table = app.tableView;
int numberOfSections = [table numberOfSections];
int numberOfRowsInSection = [table numberOfRowsInSection:numberOfSections-1];
NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRowsInSection-1 inSection:numberOfSections-1];
[table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
```

Fortunately underneath the scenes a tableView filter will actually return an subclass of UIQuery called UIQueryTableView which has the method scrollToBottom, so now you can do the following instead:

```
[app.tableView scrollToBottom];  //much nicer :)
```

### Timing Issues ###
Sometimes a view interaction will cause a longer than normal process to run, for example, touching a refresh button that makes a server call to reload the data on the screen.  This may take a few seconds, but if the next call to a UIQuery object is already running it will be looking for views that don't exist yet or whom contain stale data because the new ones haven't finished loading yet.  UIQuery provides the methods timeout and wait to help handle cases like this.

  * timeout:seconds - tells UIQuery the amount of time to take when looking for a view, default is 10 seconds
  * wait:seconds - causes UIQuery to halt it's processing for the specified amount of time, so other processes can finish

By default if UIQuery cannot find a view you are looking for it will continue to look for it every half second up until a default timeout of ten seconds.  If by then it cannot find your view it will just return an empty UIQuery object.  You can change this default for the whole app or just for a specific call, like so:

```
app.timeout = 5; //now the default timeout for all calls on app is 5 seconds
[app timeout:1].alertView //only take 1 second to look for alertView, every call following will go back to the default
```

Now let's say you wanted to get the value of a label that changes every time you click a button.  And it just so happens that calculating the new value for whatever reason takes about a second.  Using wait is a great way to handle this timing issue.  See the following:

```
UILabel *label = [app.label text@"initialValue"];
UIQuery *button = [app.button currentTitle:@"Calculate"];

button.touch; //this starts the calculation process
[app wait:2.0]; //this gives the calculation at least 2 seconds to run before the next UIQuery call
NSString *value = label.text; //now that we have waited 2 seconds we can get the correct value
```

Alternatively you can chain the wait call like so:

```
[button.touch wait:2];
//or
NSString *labelText = [[label wait:2] text];
```


---


# UIExpectation #
UIExpectation let's you set expectations on your UIViews and is available on a UIQuery object through the property "should".  If the expectation is met the spec continues, otherwise it fails.  Providing "not" will expect the opposite.  As noted before a UIQuery object itself contains a list of views, and by default it will apply an expectation to its **first** view.  If you want to apply the expectation to all the views it contains, call the property "all" beforehand.

```
//Check that the first label has the correct text
[app.label.should.have text@"User Profile"];

//Make sure all the table cells are checked
[app.tableView.tableViewCell.all.should.have accessoryType:UITableViewCellAccessoryCheckmark];

//Make sure no table cells are selected
[app.tableView.tableViewCell.all.should.not.be selected];
```

### Should Exist ###
Calling the property exist will evaluate the UIQuery object to see if it contains any resulting views.

```
app.alertView.should.exist;
[[app.label text:@"Login"] should].not.exist;
```

### Should Have ###
The property have on a UIExpectation works in two ways 1) as a property matcher and 2) as a condition evaluation.  As a property matcher "have" dynamically looks at all the properties on a UIView and compares them to the provided values.  When evaluating a condition it matches against YES.

```
//As a property Matcher
[app.textField.should.have placeholder:@"Email" text:"btknorr@gmail.com" textColor:[UIColor grayColor]];

//As a condition evaluation
UIQuery *tableView = app.tableView;
int rows = [[tableView dataSource] tableView:tableView numberOfRowsInSection:0];
[tableView.should have:(rows == 3)];
```

### Should Be ###
The property be on a UIExpectation checks against the returned BOOL from a property or method on the underlying UIView.

```
//'selected' is a property on UITableViewCell, here we make sure the last one is 'selected'
[app.tableView.tableViewCell.last.should.be selected];
```

```
UIQuery *tableView = app.tableView;
int rows = [[tableView dataSource] tableView:tableView numberOfRowsInSection:0];
[expectThat(rows) should:be(3)];
```

# UIScript #

UIScript is in it's experimental stage right now, so please use it with caution.

UIScript's goal is to provide a simple lightweight scripting language that supports all the functionality of UISpec, but without having to write Objective-C code.  Instead you write UIScript which is very similar to Smalltalk.

Currently UIScript only supports straight messages, which means there is no support for things like variables and loops or decisions (for, while, if else, etc...).  And right now UISpec recognizes only Strings, Integers, and BOOLs.

You can run a script in your test by calling the C function:
```
UIQuery * $(NSString *script, ...);
```

### Messages ###

Like in Objective-C, UIScript is based on sending messages to objects.  The only real difference in writing UIScript vs Objective-C is that you take out all the dot notation and brackets.

```
$(@"navigationButton touch");
$(@"tableView tableViewCell all should not be selected");
```

As you can see it's very similar to what you are used to writing, except without all the syntactic sugar, making the script even more readable.

### Strings ###

Strings in UISpec are just quoted values like 'Hello' or 'Good Bye', and there is no need to use the @ symbol as a prefix like you do in Objective-C.

```
$(@"navigationButton label text:'Save' touch");

$(@"textField placeholder:'Username' setText:'bkuser'");
//If you need to include a String dynamically just use NSString formatting
$(@"textField placeholder:'Username' setText:'%@'", [Config userName]);
```

### Integers ###

Currently Integers are the only number support in UIScript.  We hope to have support for decimals very soon.

```
$(@"tableView should have numberOfSections:3");

$(@"label text:'Returns' parent tableViewCell should have accessoryType:3");
//Or you can use NSString formatting
$(@"label text:'Returns' parent tableViewCell should have accessoryType:%d", UITableViewCellAccessoryCheckmark);
```

### BOOLs ###

The BOOLs YES and NO are also supported in UIScript.

```
$(@"tableView tableViewCell first should have isSelected:YES");
$(@"tableView tableViewCell last should have isSelected:NO");

//Or you can use NSString formatting
int rows = $(@"tableView numberOfRowsInSection:0");
$(@"tableView should have:%@", rows==3);
```

### Example ###

Here is the itShouldUpdateUserRoles example from the demo rewritten using UIScript
```
-(void)itShouldUpdateUserRoles {
  [self addTestUser];

  $(@"label with text:'Brian Knorr' touch");
  $(@"label text:'User Roles' touch");

  $(@"tableView scrollToBottom");
  $(@"label text:'Returns' touch");
  $(@"label text:'Returns' parent tableViewCell should be selected");
  $(@"label text:'Returns' parent tableViewCell should have accessoryType:%d", UITableViewCellAccessoryCheckmark);
	
  $(@"label text:'Returns' touch");
  $(@"label text:'Returns' parent tableViewCell should have accessoryType:%d", UITableViewCellAccessoryNone);
	
  $(@"view:'UINavigationItemButtonView' touch");
  $(@"view:'UINavigationItemButtonView' touch");

  [self deleteTestUser];
}
```