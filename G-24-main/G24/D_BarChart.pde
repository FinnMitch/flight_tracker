/**
 * BarChart has variable x and y axis settings from dropdown selections, variable bar numbers based on user text input
 * BarChart title and text info displayed within the chart is also all variable dependent on sorting
 * 
 * Written by Finn and Chloe
 **/

class BarChart extends Display {
  String column;
  IntDict xCounts;
  FloatDict xValues;
  String[] topX;
  float[] topValues;
  int bars;
  String msg = "";
  String valueType = "count";

  //user input bars textbox
  float tbX, tbY, tbW, tbH;
  String tbText = "";
  boolean tbSelected = false;

  public BarChart (boolean visible, Table tableToDisplay, String column, int bars) {
    super(visible, tableToDisplay);
    this.column = column;
    this.bars = bars;
    tbW = 100;
    tbH = 35;
    tbX = width - 150;
    tbY = 260;
    makeChart();
  }

  public void setColumn(String newColumn) {
    if (!newColumn.equals(column)) {
      column = newColumn;
      makeChart();
    }
  }


  public void updateChart(Table nextTable) {
    super.setTable(nextTable);
    makeChart();
  }

  public void setValueType(String type) {
    this.valueType = type;
  }

  public void makeChart() {//NEED TO SHOW NO RESULTS
    if (valueType.equals("Lateness")) {
      processLatenessData();
    } else if (valueType.equals("Distance")) {
      processDistanceData();
    } else {
      // frequency default
      processByFrequency();
    }
  }

  private void processByFrequency() {
    xCounts = new IntDict();
    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      String variable = super.tableToDisplay.getString(i, column);
      if (variable != null && variable.length() > 0) {
        xCounts.increment(variable);
      }
    }
    sortAndExtractCounts();
  }

  private void processDistanceData() {
    // FloatDict to store average distance by category
    xValues = new FloatDict();
    IntDict categoryCounts = new IntDict();

    // avg distance
    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      String category = super.tableToDisplay.getString(i, column);

      if (category != null && category.length() > 0) {
        int distance = super.tableToDisplay.getInt(i, "DISTANCE");

        // add category in Dict
        if (!xValues.hasKey(category)) {
          xValues.set(category, distance);
          categoryCounts.set(category, 1);
        } else {
          // update sum,count
          float currentSum = xValues.get(category);
          int currentCount = categoryCounts.get(category);
          xValues.set(category, currentSum + distance);
          categoryCounts.set(category, currentCount + 1);
        }
      }
    }

    // avgs
    for (String category : xValues.keyArray()) {
      float sum = xValues.get(category);
      int count = categoryCounts.get(category);
      float average = sum / count;
      xValues.set(category, average);
    }

    sortAndExtractValues();
  }

  private void processLatenessData() {
    // FloatDict to store avg lateness
    xValues = new FloatDict();
    IntDict categoryCounts = new IntDict();

    boolean hasLatenessColumn = false;
    for (int i = 0; i < super.tableToDisplay.getColumnCount(); i++) {
      if (super.tableToDisplay.getColumnTitle(i).equals("latenessNum")) {
        hasLatenessColumn = true;
        break;
      }
    }

    // If no latenessNum, frequency default
    if (!hasLatenessColumn) {
      processByFrequency();
      return;
    }

    // avg lateness for category
    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      String category = super.tableToDisplay.getString(i, column);

      if (category != null && category.length() > 0) {
        int latenessValue = super.tableToDisplay.getInt(i, "latenessNum");

        // Skip cancelled/missing
        if (latenessValue > -8000) {
          // add category to Dict
          if (!xValues.hasKey(category)) {
            xValues.set(category, latenessValue);
            categoryCounts.set(category, 1);
          } else {
            // update sum, count
            float currentSum = xValues.get(category);
            int currentCount = categoryCounts.get(category);
            xValues.set(category, currentSum + latenessValue);
            categoryCounts.set(category, currentCount + 1);
          }
        }
      }
    }

    //avgs
    for (String category : xValues.keyArray()) {
      float sum = xValues.get(category);
      int count = categoryCounts.get(category);
      float average = sum / count;
      xValues.set(category, average);
    }

    sortAndExtractValues();
  }

  public void sortAndExtractCounts() {
    xCounts.sortValuesReverse();

    // Get the top amount 'bars' number of items
    String[] keys = xCounts.keyArray();
    int numTop = min(bars, keys.length);
    topX = new String[numTop];
    topValues = new float[numTop];

    for (int i = 0; i < numTop; i++) {
      topX[i] = keys[i];
      topValues[i] = xCounts.get(keys[i]);
    }
  }
 
  public void sortAndExtractValues() {
    // Sort by value (higher values first)
    String[] allX = xValues.keyArray();
    float[] allValues = xValues.valueArray();
    Integer[] index = new Integer[allX.length];
    for (int i = 0; i < allX.length; i++) {
      index[i] = i;
    }
    for (int i = 0; i < index.length - 1; i++) {
      for (int j = 0; j < index.length - 1 - i; j++) {
        if (allValues[index[j]] < allValues[index[j + 1]]) {
          int temp = index[j];
          index[j] = index[j + 1];
          index[j + 1] = temp;
        }
      }
    }
    int numTop = min(bars, allX.length);
    topX = new String[numTop];
    topValues = new float[numTop];
    for (int i = 0; i < numTop; i++) {
      topX[i] = allX[index[i]];
      topValues[i] = allValues[index[i]];
    }
  }

  @Override
    public void draw() {
    int leftMargin = 50;
    int rightMargin = 150;
    int bottomMargin = 100;
    int topMargin = 150;

    stroke(255);
    line(leftMargin, height - bottomMargin, leftMargin, topMargin);
    line(leftMargin, height - bottomMargin, width - rightMargin, height - bottomMargin);

    float chartWidth = width - leftMargin - rightMargin;
    float chartHeight = height - bottomMargin - topMargin;

    // chart title
    textAlign(CENTER, TOP);
    textSize(18);
    String chartTitle = "";
    if (valueType.equals("Lateness")) {
      chartTitle = "Average Lateness by " + formatColumnName(column);
    } else if (valueType.equals("Distance")) {
      chartTitle = "Average Distance by " + formatColumnName(column);
    } else {
      chartTitle = "Frequency of " + formatColumnName(column);
    }
    text(chartTitle, width/2, topMargin - 40);

    // y-axis label based on valueType
    fill(0);
    textAlign(RIGHT, CENTER);
    pushMatrix();
    translate(25, height/2 - 50);
    rotate(-HALF_PI);
    if (valueType.equals("Lateness")) {
      text("Average Lateness (minutes)", 0, 0);
    } else if (valueType.equals("Distance")) {
      text("Average Distance (miles)", 0, 0);
    } else {
      text("Count", 0, 0);
    }
    popMatrix();

    if (super.tableToDisplay.getRowCount() > 0) {
      int numBars = topX.length;
      float gap = 10;
      float barWidth = (chartWidth - (numBars + 1) * gap) / numBars;

      //to scale bars
      float maxValue = 0;
      for (float value : topValues) {
        maxValue = max(maxValue, value);
      }

      int r = 70;
      int g = 130;
      int b = 180;
      int divisor = (bars > 0) ? 245 / bars : 1;

      for (int i = 0; i < numBars; i++) {
        float barHeight = map(topValues[i], 0, maxValue, 0, chartHeight);
        float xPos = leftMargin + gap + i * (barWidth + gap);
        float yPos = height - bottomMargin - barHeight;

        fill(r, g, b);
        noStroke();
        rect(xPos, yPos, barWidth, barHeight, 10);

        fill(0);
        textSize(12);
        textAlign(CENTER, CENTER);

        float currentBarXpos = xPos + barWidth / 2;
        if (i < numBars) {
          float nextBarXpos = xPos + (barWidth + gap) + barWidth / 2;
          if ((nextBarXpos - currentBarXpos) < 80) {
            pushMatrix();
            translate(currentBarXpos, height - bottomMargin + 50);
            rotate(-HALF_PI);
            text(topX[i], 0, 0);
            popMatrix();
          } else {
            text(topX[i], currentBarXpos, height - bottomMargin + 15);
          }
        } else {
          text(topX[i], currentBarXpos, height - bottomMargin + 15);
        }

        // gradient updates
        g += divisor/2.5;
        r += divisor/2;
        b += divisor;

        // change display at top of each bar based on type
        String valueLabel;
        if (valueType.equals("lateness")) {
          valueLabel = nf(topValues[i], 0, 1) + " min";
        } else if (valueType.equals("distance")) {
          valueLabel = nf(topValues[i], 0, 1) + " mi";
        } else {
          valueLabel = nf(topValues[i], 0, 0);
        }
        text(valueLabel, xPos + barWidth/2, yPos - 10);
      }
    } else {
      textAlign(CENTER, CENTER);
      text("No flights to display!", 500, 500);
    }

    //Drawing the textbox
    fill(70, 90, 140);
    textSize(16);
    textAlign(CENTER, CENTER);
    text("Number of bars:", width - 95, 245);
    drawTextBox();
  }

  void drawTextBox() {
    fill(250);
    rect(tbX, tbY, tbW, tbH, 5);
    fill(0);
    textAlign(CENTER, CENTER);
    text(tbText, tbX + tbW/2, tbY + tbH/2);

    fill(0);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(msg, width/2, tbY - 20);
  }

  // called in mousePressed()
  // move to EventHandler & widget
  void doMousePressed(float mx, float my) {
    tbSelected = (mx > tbX && mx < tbX + tbW && my > tbY && my < tbY + tbH);
  }

  // called in keyPressed() or updates textbox text (3 digits)
  // If adding any more text input, move to EventHandler
  boolean doKeyPressed(char key, int keyCode) {
    if (tbSelected) {
      if (keyCode == BACKSPACE && tbText.length() > 0) {
        tbText = tbText.substring(0, tbText.length() - 1);
      } else if (keyCode == ENTER) {
        try {
          int userValue = int(tbText);
          if (userValue > 0 && userValue <= (valueType.equals("count") ? xCounts.size() : xValues.size())) {
            bars = userValue;
            if (valueType.equals("count")) {
              sortAndExtractCounts();
            } else {
              sortAndExtractValues();
            }
          }
        }
        catch (Exception e) {
        }

        tbSelected = false;
        tbText = "";
        return true;
      } else if (tbText.length() < 3 && key >= '0' && key <= '9') {
        tbText += key;
      }
    }
    return false;
  }

  // column name formatting for display
  private String formatColumnName(String columnName) {
    switch(columnName) {
    case "DEST_STATE_ABR":
      return "Destination State";
    case "ORIGIN_STATE_ABR":
      return "Origin State";
    case "MKT_CARRIER":
      return "Airline";
    case "ORIGIN":
      return "Departure Airport";
    case "DEST":
      return "Arrival Airport";
    case "FL_DATE":
      return "Flight Date";
    default:
      return columnName;
    }
  }
}

/* Integrated BarChart into program structure extending Display;
 * Needs further integration to be more modular
 * Chloe 1/4/2025
 *
 * Removed unused barColor method & variables
 * BarChart now changes x axis based on dropdown menu (see EventHandler & main for details)
 * Chloe 6/4/25
 *
 * Changed UI, added additional sorting and formatting
 * Chloe 7/4/25
 */
