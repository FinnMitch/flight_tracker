//ABSTRACT DISPLAY CLASS
//Written by Honor
//List, Map and BarChart are all subclasses, but this way can be trested as a group.
abstract class Display {
  //Attributes
  private boolean visible;
  private Table tableToDisplay;


  //Constructor
  Display(boolean visible, Table tableToDisplay) {
    this.visible = visible;
    this.tableToDisplay = tableToDisplay;
  }

  //Methods
  void draw() {
  }//BASIC DRAW METHOD IS OVERRIDEN BY SUBCLASSES

  //Sets & Gets
  public void setVisibility(boolean visible) {
    this.visible = visible;
  }

  public void setTable(Table tableToDisplay) {
    this.tableToDisplay = tableToDisplay;
  }

  public boolean getVisibility() {
    return visible;
  }
}
