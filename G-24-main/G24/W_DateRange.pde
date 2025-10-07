/*
 * For choosing a date range for filtering options; separated out from SortAndFilter/FilterDropdown for clarity and ease of access
 * Chloe 7/4/25
 */
class DateRange extends Widget {
  DropDownMenu dateDrop; //contains date range dropdown select
  String label;
  color labelColor;
  PFont labelFont;

  public DateRange(int x, int y, int width, int height, String label, color labelColor, PFont labelFont, int event, ArrayList<String> dates) {
    super(x, y, width, height, event);
    this.label = label;
    this.labelColor = labelColor;
    this.labelFont = labelFont;
    int labelWidth = 150;
    dateDrop = new DropDownMenu(x + labelWidth, y, width - labelWidth, height, event, dates); 
    // the above creates the secondary dropdown that appears next to the main filterDropDown date option
  }

  @Override
    public void draw() {
    fill(labelColor);
    textFont(labelFont);
    textAlign(RIGHT, CENTER);
    text(label, x + 140, y + height/2);
    dateDrop.draw();
  }

// Mouse events, mouse x & y position
  @Override
    public int getEvent(int mx, int my) {
    return dateDrop.getEvent(mx, my);
  }

//choosing the date range
  public void selectOption(int mx, int my) {
    dateDrop.selectOption(mx, my);
  }

  public String getSelectedDate() {
    return dateDrop.getSelectedOption();
  }
}
