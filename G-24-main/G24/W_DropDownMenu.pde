/*
 * DropDownMenu Class, subclass of Widget that allows user to choose from a preexisting list of options
 *
 * Based on code written by Larisa
 * Honor 01/04/2025
 */
class DropDownMenu extends Widget {
  //Attributes
  private ArrayList<String> options;
  private String selectedOption;
  private int optionHeight;
  private final int PADDING;
  private boolean showOptions;

  //Constructor
  public DropDownMenu (int x, int y, int width, int optionHeight, int event, ArrayList<String> options) {
    super(x, y, width, (optionHeight * (options.size() + 1)), event);

    this.options = (ArrayList<String>) options.clone();
    this.optionHeight = optionHeight;
    this.selectedOption = this.options.get(0);
    showOptions = false;
    PADDING = 5;
  }

  //Methods
  @Override
    public void draw() {
    textAlign(LEFT, TOP);
    fill(190, 215, 255);
    rect(x, y, width, optionHeight, 5);
    fill (0);
    text(selectedOption, x + PADDING, y + PADDING);

    if (showOptions) {
      fill(27, 36, 82);
      rect(x, y + optionHeight, width, height - optionHeight, 5);
      fill(255);

      for (int i = 0; i < options.size(); i++) {
        text(options.get(i), x + PADDING, y + ((i + 1) * optionHeight) + PADDING);
      }
    }
  }

  @Override
    public int getEvent(int mx, int my) { //Returns unique ventNumber for eventHandler
    if (mx > x && mx < x + width && my > y && my < y + height) {
      return event;
    }
    return 0;
  }

  public void selectOption(int mx, int my) { //Used to select desired option from list options
    //was having issues through eventHandler, so this is here for now
    // println("made it to dropdown select");
    if (!showOptions) {
      showOptions = true;
    } else {
      int optionIndex = ((my - y) / optionHeight) - 1;
      if (optionIndex >= 0 && optionIndex < options.size()) {
        selectedOption = options.get(optionIndex);
        showOptions = false;
      } else {
        showOptions = false;
      }
    }
  }

  public void hover(int mx, int my) {
    // No hover behavior needed for now; are we adding it? -Chloe
  }
  public String getSelectedOption() {
    return selectedOption;
  }

  public void setSelectedOption(String option) {
    selectedOption = option;
  }
}
