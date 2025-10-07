/**
 * Button is a subclass of widget and is simply a box with a label and a border
 *
 * Honor 28/03/2025
 *
 * Edited by Finn. Added rounded edges and proper text alignemnt.
 **/
class Button extends Widget {
  //Attributes
  private String label;
  private color widgetColor, labelColor, strokeColor;
  private PFont widgetFont;

  //Constructor
  Button (int x, int y, int width, int height, String label, color widgetColor, PFont widgetFont, int event) {
    super(x, y, width, height, event);
    this.label = label;
    this.widgetColor = widgetColor;
    labelColor = color(0);
    strokeColor = color(0);
    this.widgetFont = widgetFont;
  }

  //Methods
  @Override
    void draw() {
    stroke(strokeColor);
    fill(widgetColor);
    rect(x, y, super.width, super.height, 10);
    fill(labelColor);
    textFont(widgetFont);
    textAlign(CENTER, CENTER);

    //center of button
    float textX = x + width / 2;
    float textY = y + height / 2;
    text(label, textX, textY);
  }

  /* NOTE: WAS USED TO HIGHLIGHT WIDGET BORDER FOR HOVER FUNCTIONALITY
   void setStrokeColor(color newColor) {
   strokeColor = newColor;
   }*/
}
