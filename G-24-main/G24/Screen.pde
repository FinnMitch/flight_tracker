/**
 * Screen acts as a container for widgets and displays
 * That way you can only access the widgets/displays in your current screen
 *
 * Honor 28/03/2025
 **/
class Screen {
  private ArrayList<Widget> widgets;
  private ArrayList<Display> displays;
  private color backgroundColor;

  //Constructor
  Screen (color bgc) {
    widgets = new ArrayList<Widget>();
    displays = new ArrayList<Display>();
    backgroundColor = color(bgc);
  }

  //Methods
  int getEvent(int mx, int my) {//returns the event number of the widget the mouse is currently on
    int event = 0;//returns 0 if the mouse isn't over a widget
    for (int i = 0; i < widgets.size(); i++) {
      event =  widgets.get(i).getEvent(mx, my);
      if (event != 0) {
        return event;
      }
    }
    return event;
  }

  void addWidget(Widget w) {
    widgets.add(w);
  }

  //for all the widgets on the screen - do we need both or should we combine? -chloe
  public ArrayList<Widget> getWidgets() {
    return widgets;
  }

  void addDisplay(Display d) {
    displays.add(d);
  }

  public ArrayList<Display> getDisplays() {
    return displays;
  }

  //Added welcome screen image to home page -Chloe 6/4/25
  void draw() {
    if (currentScreen == welcomeScreen)
    {
      background(img);
    } else {
      background(backgroundColor);
    }
    for (Display d : displays) {
      if (d.getVisibility()) {
        d.draw();
      }
    }

    // Draw all widgets
    for (Widget w : widgets) {
      if (w.getVisibility()) {
        w.draw();
      }
    }
  }

  public void checkHover() {//Hover functionality isn't currently implemented, dropdoen menus toggle when clicked instead.
    for (int i = 0; i < widgets.size(); i++) {
      if (widgets.get(i) instanceof DropDownMenu) {
        ((DropDownMenu) widgets.get(i)).hover(mouseX, mouseY);
      }
    }
  }
}

//NOTE: HOVER FUNCTIONALITY NOT NECESSARY YET, BUT CAN BE ADDDED IN
/*void hover() {
 int event;
 for (int i = 0; i < widgets.size();  i++) {
 Widget w = widgets.get(i);
 event = w.getEvent(mouseX, mouseY);
 if (event != 0) {
 w.setStrokeColor(255);
 } else {
 w.setStrokeColor(0);
 }
 }
 }*/
