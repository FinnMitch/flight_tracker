/**
 * Widget acts as an abstract superclass for all the user input options,
 * e.g. button, dropdown menu, checkbox subclasses
 *
 * Each widget has an event number which determines what code will run when the user interacts with it (see EventHandler class)
 *
 * Honor 28/03/2025
 *
 * Widget also has Visiblity, similar to Display -Chloe
 **/

class Widget {
  protected int x, y, width, height;
  protected int event;
  protected boolean visible;

  //Constructor
  Widget(int x, int y, int width, int height, int event) {
    this.width = width;
    this.height = height;
    this.x = x;
    this.y = y;
    this.event = event;
    visible = true;
  }

  //Methods
  public int getEvent (int mx, int my) {
    if (mx > x && mx < x + width && my > y && my < y + height && visible) { //Changed so that event num only returned when event is visible HM
      return event; //This is so that widgets can overlap & the user can't interact with the invisible one.
    }
    return 0;//Returns 0 if mouse is not on the current widget
  }

  public int getEvent() {//Uses polymorphism to return the event of the object, without checking if the mouse is over it
    return event;
  }

  public void setVisibility(boolean visible) { //Set and Get methods for widget visibility between Displays -Chloe
    this.visible = visible;
  }

  public boolean getVisibility() {
    return visible;
  }


  public void draw() {//This is a very basic draw method that is overriden in each of the subclasses
    if (visible) {
      stroke(0);
      fill(255);
      rect(x, y, width, height);
    }
  }
}
