/*
 * For our table/list display
 * You can view all the flight data provided in a clear and readable format that you scroll through; includes customized sorting and filtering options 
 * for the user to interact with the lists. Has extra Sort by Date sorting feature (written by Finn) in place of other BarChart Display sort options
 * Color-coded delay status column; readable data output; stars selected sorting column
 * Chloe 7/4/25
 */
class List extends Display {
  String column;
  int maxRows = 55;
  int startRow = 0;
  float rowHeight = 30;
  float headerHeight = 40;
  String sortMethod = "None"; //current sort

  public List(boolean visible, Table tableToDisplay, String column) {
    super(visible, tableToDisplay);
    this.column = column;
  }

  public void setColumn(String newColumn) {
    if (!newColumn.equals(column)) {
      column = newColumn;
    }
  }

  public void setSortMethod(String method) {
    this.sortMethod = method;
  }

  public void updateDisplay(Table nextTable) {
    super.setTable(nextTable);
    // Reset scroll position when table is updated
    startRow = 0;
  }

  @Override
    public void draw() {
    int leftMargin = 50;
    int topMargin = 180; // Positioned below the bar chart
    int listWidth = width - 250;
    int listHeight = 490;

    // Draw list background
    fill(240);
    rect(leftMargin, topMargin, listWidth, listHeight, 5);

    // Draw header
    fill(60, 80, 115);
    rect(leftMargin, topMargin, listWidth, headerHeight, 5, 5, 0, 0);

    // Draw column headers
    fill(255);
    textSize(14);
    textAlign(LEFT, CENTER);

    // Define the columns to display and their widths
    String[] columns = {"FL_DATE", "MKT_CARRIER", "ORIGIN", "DEST", "DISTANCE"};
    float[] columnWidths = {0.2f, 0.15f, 0.2f, 0.2f, 0.15f};

    // Check if LATE column exists for status display
    for (int i = 0; i < super.tableToDisplay.getColumnCount(); i++) {
      if (super.tableToDisplay.getColumnTitle(i).equals("LATE")) {
        // Adjust column widths for lateness display
        columns = new String[]{"FL_DATE", "MKT_CARRIER", "ORIGIN", "DEST", "LATE", "DISTANCE"};
        columnWidths = new float[]{0.15f, 0.15f, 0.15f, 0.15f, 0.15f, 0.15f};
        break;
      }
    }

    // Draw the header titles
    float xPos = leftMargin + 10;
    for (int i = 0; i < columns.length; i++) {
      float colWidth = columnWidths[i] * listWidth;
      String displayName = formatColumnTitle(columns[i]);

      // Highlight the column header if it's the sort field
      if ((columns[i].equals("DISTANCE") && sortMethod.equals("Distance")) ||
        (columns[i].equals("LATE") && sortMethod.equals("Lateness")) ||
        (columns[i].equals("FL_DATE") && sortMethod.equals("Date"))) {
        // Draw an arrow indicator next to the column name
        text(displayName + " *", xPos, topMargin + headerHeight/2);
      } else {
        text(displayName, xPos, topMargin + headerHeight/2);
      }

      xPos += colWidth;
    }

    // Calculate how many rows we can show
    int visibleRows = min(maxRows, floor((listHeight - headerHeight) / rowHeight));

    // Adjust maxRows based on listHeight
    maxRows = visibleRows;

    // Calculate max startRow
    int totalRows = super.tableToDisplay.getRowCount();
    int maxStartRow = max(0, totalRows - maxRows);
    startRow = constrain(startRow, 0, maxStartRow);

    // Draw rows
    for (int i = 0; i < visibleRows; i++) {
      int rowIndex = startRow + i;
      if (rowIndex >= totalRows) break;

      fill(250);
      rect(leftMargin, topMargin + headerHeight + i * rowHeight, listWidth, rowHeight);

      // Draw cell data
      fill(0);
      textSize(12);
      TableRow row = super.tableToDisplay.getRow(rowIndex);

      float x = leftMargin + 10;
      for (int j = 0; j < columns.length; j++) {
        float colWidth = columnWidths[j] * listWidth;
        String value = "";

        // Format the cell value based on column type
        if (columns[j].equals("LATE")) {
          String lateValue = row.getString("LATE");

          // Format and color-code based on lateness value
          if (lateValue.equals("[cancelled]")) {
            value = "Cancelled";
            fill(50);  // grey for cancelled
          } else if (lateValue.equals("N/A")) {
            value = "No Data";
            fill(150);  // Gray for missing data
          } else if (lateValue.startsWith("+")) {
            // Late flights - already has "+" sign
            lateValue = lateValue.substring(1);
            int minutes = Integer.parseInt(lateValue);
            value = lateValue + " min late";


            fill(220, 0, 0);  // Default red for late
          } else if (lateValue.startsWith("-")) {
            lateValue = lateValue.substring(1);

            // Early flights - keep minus sign
            try {
              int minutes = Integer.parseInt(lateValue);
              value = lateValue + " min early";
            }
            catch (NumberFormatException e) {
              value = lateValue + " min early";
            }
            fill(0, 150, 0);  // Green for early & on time
          } else if (lateValue.equals("0")) {
            value = "On Time";
            fill(0, 150, 0);
          } else {
            value = lateValue;  // Just use the value as-is for any other case
            fill(0);
          }
        } else if (columns[j].equals("FL_DATE")) {
          value = row.getString(columns[j]);
        } else if (columns[j].equals("DISTANCE")) {
          // Highlight distance values when sorting by distance
          int distance = row.getInt(columns[j]);
          value = distance + " mi";
        } else {
          value = row.getString(columns[j]);
        }

        text(value, x, topMargin + headerHeight + i * rowHeight + rowHeight/2);
        x += colWidth;
        fill(0);
      }
    }

    fill(70, 90, 140);
    textSize(16);
    textAlign(CENTER, CENTER);

    // titles based on sort
    String titleText = "Flight List";
    if (sortMethod.equals("Lateness")) {
      titleText += " (Sorted by Delay Status)";
    } else if (sortMethod.equals("Distance")) {
      titleText += " (Sorted by Distance)";
    } else if (sortMethod.equals("Date")) {
      titleText += " (Sorted by Date)";
    }
    titleText += " (" + min(totalRows, maxRows) + " of " + totalRows + " flights)";

    text(titleText, listWidth/2 + 50, topMargin - 50);
  }

  public void doMouseWheel(float count) {
    startRow += count;

    // scrolling bounds
    int totalRows = super.tableToDisplay.getRowCount();
    int maxStartRow = max(0, totalRows - maxRows);
    startRow = constrain(startRow, 0, maxStartRow);
  }

  // Column title formatting
  private String formatColumnTitle(String columnName) {
    switch(columnName) {
    case "FL_DATE":
      return "Date";
    case "MKT_CARRIER":
      return "Airline";
    case "ORIGIN":
      return "From";
    case "DEST":
      return "To";
    case "DISTANCE":
      return "Miles";
    case "LATE":
      return "Status";
    default:
      return columnName;
    }
  }
}
