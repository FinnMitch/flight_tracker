/**
 * Flight Data Visualization Program
 * ---------------------------------
 * This project loads and visualizes U.S. flight data from a CSV file.
 * It uses a modular structure with a custom Screen class to manage the different views of the welcome screen and data screen. 
 * The three main visualizations (bar chart, map, and list) shown on the data screen are subclasses of the Display superclass
 * Users can filter data by: frequency, lateness, and distance; they can sort data by: flight dates, origin and arrival airports, and more
 **/


import java.util.ArrayList;
import java.util.Map;

PImage img;
PImage plane;
Table allFlights;
Screen currentScreen;
Screen welcomeScreen;
Screen dataScreen;
EventHandler eventHandler;
SortAndFilter sortFilter;

void setup() { //Loads images, loads flight data from CSV into Table, initialises Screens, adds Widgets & Displays to those Screens
  frameRate(300);
  size(1000, 800);
  img = loadImage("skywriting.png");
  plane = loadImage("plane2.png");
  PFont myFont = loadFont("Ubuntu-Regular-18.vlw");
  textFont(myFont);
  loadCSVToTable();
  eventHandler = new EventHandler();
  sortFilter = new SortAndFilter(allFlights);

  //Creates screens and adds widgets & displays to them
  welcomeScreen = new Screen(color(255));
  dataScreen = new Screen(color(215, 230, 250));
  currentScreen = welcomeScreen;

  welcomeScreen.addWidget(new Button(width/2 - 100, height/2 + 100, 200, 50, "Enter Flight Program", color(150, 220, 255), myFont, 1));
  dataScreen.addWidget(new Button(50, 25, 100, 40, "Exit", color(150, 195, 255), myFont, 2));
  dataScreen.addWidget(new Button(width-150, 25, 100, 40, "Update", color(150, 195, 255), myFont, 3));
  dataScreen.addWidget(new Button(width-150, 75, 100, 40, "Bar Chart", color(190, 215, 255), myFont, 6));
  dataScreen.addWidget(new Button(width-150, 125, 100, 40, "Map", color(190, 215, 255), myFont, 7));
  dataScreen.addWidget(new Button(width-150, 175, 100, 40, "List", color(190, 215, 255), myFont, 8));
  Widget dateWidget = new Button(380, 30, 180, 30, "Sort by Date", color(190, 215, 255), myFont, 12);
  dataScreen.addWidget(dateWidget);

//1st Dropdown menu for sorting (used in BarChart & List))
  ArrayList<String> sortOptions = new ArrayList<String>();
  sortOptions.add("Frequency");
  sortOptions.add("Lateness");
  sortOptions.add("Distance");
  Widget sortOptionsMenu = new DropDownMenu(180, 30, 180, 30, 5, sortOptions);
  dataScreen.addWidget(sortOptionsMenu);

//2nd Dropdown menu for sorting (only used for bar chart x axis)
  ArrayList<String> columnOptions = new ArrayList<String>();
  columnOptions.add("Destination State");
  columnOptions.add("Origin State");
  columnOptions.add("Airline");
  columnOptions.add("Departure Airport");
  columnOptions.add("Arrival Airport");
  columnOptions.add("Flight Date");
  Widget columnOptionsMenu = new DropDownMenu(380, 30, 180, 30, 4, columnOptions);
  dataScreen.addWidget(columnOptionsMenu);

  FilterDropdown filterDropdown = new FilterDropdown(580, 30, 120, 30, myFont, 9);
  dataScreen.addWidget(filterDropdown);

  //add Displays
  dataScreen.addDisplay(new BarChart(true, allFlights, "DEST_STATE_ABR", 10));
  dataScreen.addDisplay(new Map(false, allFlights));
  dataScreen.addDisplay(new List(false, allFlights, "DEST_STATE_ABR"));

  eventHandler.setWidgetVisibilityControl(columnOptionsMenu, sortOptionsMenu, dateWidget);
  columnOptionsMenu.setVisibility(true);
  sortOptionsMenu.setVisibility(true);
  dateWidget.setVisibility(false);
}

void draw() { //Draws only the current Screen
  cursor(plane);
  noStroke();
  currentScreen.draw();
}

void mousePressed() { //Each widget has a unique event Number, which is obtained here when the mouse is pressed and passed to eventHandler
  int eventCode = currentScreen.getEvent(mouseX, mouseY);
//  println("Mouse pressed, event code: " + eventCode);

  // For event 9 (filter dropdown main button), only use the event handler
  if (eventCode == 9) {
    eventHandler.handleMousePress(eventCode);
  } else if (eventCode != 0) {
    eventHandler.handleMousePress(eventCode);
  }
  // If event 0, check if in filter dropdown or Map
  else {
    for (Widget w : currentScreen.getWidgets()) {
      if (w instanceof FilterDropdown) {
        FilterDropdown fd = (FilterDropdown)w;
        fd.handleClick(mouseX, mouseY);
        break;
      }
    }

    for (Display d : currentScreen.getDisplays()) {
      if (d instanceof Map && d.getVisibility()) {
        ((Map)d).doMousePressed(mouseX, mouseY);
      }
    }
  }


  // In BarChart, sets boolean of whether or not textbox is selected
  for (Display d : currentScreen.getDisplays()) {
    if (d instanceof BarChart) {
      ((BarChart)d).doMousePressed(mouseX, mouseY);
    }
  }
}

// Hover functionality available across all screens & displays
// Used for popup display in Map
// For dropdown menus is currently not implemented & dropdown menus are toggled when clicked instead
void mouseMoved() { 
  eventHandler.handleMouseHover(currentScreen.getEvent(mouseX, mouseY));
}


void keyPressed() //Only used in BarChart; used to enter number of bars into "Number of Bars" text box
{
  for (Display d : currentScreen.getDisplays()) {
    if (d instanceof BarChart) {
      if (((BarChart)d).doKeyPressed(key, keyCode)) {
        break;
      }
    }
  }
}


//mouseDragged & mouseReleased both added navigating across the map image in Map subclass - CD 7/4/25
void mouseDragged() {
  for (Display d : currentScreen.getDisplays()) {
    if (d instanceof Map && d.getVisibility()) {
      ((Map)d).doMouseDragged(mouseX, mouseY);
    }
  }
}

void mouseReleased() {
  for (Display d : currentScreen.getDisplays()) {
    if (d instanceof Map && d.getVisibility()) {
      ((Map)d).doMouseReleased();
    }
  }
}


//Deals with mouse scrolling in different Displays & Widgets
void mouseWheel(MouseEvent event) {
  // +scroll = down; -scroll = up
  int e = (event.getCount());

  // If FilterDropdown is visible, pass the wheel(scroll) event
  boolean handledByFilter = false;
  for (Widget w : currentScreen.getWidgets()) {
    if (w instanceof FilterDropdown) {
      FilterDropdown fd = (FilterDropdown)w;
      fd.handleWheel(e);
      handledByFilter = true;
      break;
    }
  }

  // Pass to list display
  for (Display d : currentScreen.getDisplays()) {
    if (d instanceof List) {
      ((List)d).doMouseWheel(e);
    } else if (d instanceof Map && d.getVisibility()) {
      ((Map)d).doMouseWheel(e);
    }
  }
}


void loadCSVToTable() { //Loads the flight data from the CSV and puts it into a Table to be used by the rest of the program
  String[] titles = {"FL_DATE", "MKT_CARRIER", "MKT_CARRIER_FL_NUM", "ORIGIN", "ORIGIN_CITY_NAME", "ORIGIN_STATE_ABR", "ORIGIN_WAC", "DEST", "DEST_CITY_NAME", "DEST_STATE_ABR", "DEST_WAC", "CRS_DEP_TIME", "DEP_TIME", "CRS_ARR_TIME", "ARR_TIME", "CANCELLED", "DIVERTED", "DISTANCE"};
  int[] types = {Table.STRING, Table.STRING, Table.INT, Table.STRING, Table.STRING, Table.STRING, Table.INT, Table.STRING, Table.STRING, Table.STRING, Table.INT, Table.INT, Table.INT, Table.INT, Table.INT, Table.INT, Table.INT, Table.INT};
  allFlights = loadTable("flights2k.csv");
  allFlights.setColumnTitles(titles);
  allFlights.removeRow(0); //Removes column names from first row of the table
  allFlights.setColumnTypes(types);
  allFlights.replaceAll(" 00:00", "", "FL_DATE"); //Removes minutes and seconds from date column
  calculateLateness();
}

//Calculate & add lateness column (called in loadCSVToTable() directly above)
void calculateLateness() {
  for (TableRow row : allFlights.rows()) {
    // Check if flight was cancelled
    int cancelled = row.getInt("CANCELLED");

    if (cancelled == 1) {
      // If flight was cancelled, mark as [cancelled]
      row.setString("LATE", "[cancelled]");
    } else {
      // Get scheduled and actual arrival times
      int scheduledArrival = row.getInt("CRS_ARR_TIME");
      int actualArrival = row.getInt("ARR_TIME");

      // Check if we have valid times (some might be missing or 0)
      if (scheduledArrival > 0 && actualArrival > 0) {
        // Convert HHMM times to minutes for easier calculation
        int scheduledMinutes = convertToMinutes(scheduledArrival);
        int actualMinutes = convertToMinutes(actualArrival);

        // Calculate difference in minutes
        int lateDifference = actualMinutes - scheduledMinutes;

        //for midnight+
        if (lateDifference < -720) {  // past midnight
          lateDifference += 1440;     // +24hrs (1440 minutes)
        } else if (lateDifference > 720) { // reverse
          lateDifference -= 1440;     // -24 hours
        }

        // lateness value formatting
        if (lateDifference > 0) {
          row.setString("LATE", "+" + lateDifference);  // Late (positive)
        } else if (lateDifference < 0) {
          row.setString("LATE", String.valueOf(lateDifference));  // Early (negative)
        } else {
          row.setString("LATE", "0");  // On time
        }
      } else {
        // no arrival listed
        row.setString("LATE", "N/A");
      }
    }
  }
}

// Converts the HHMM format of the CSV's time columns to minutes for easier sorting -CD
int convertToMinutes(int timeHHMM) {
  int hours = timeHHMM / 100;
  int minutes = timeHHMM % 100;
  return hours * 60 + minutes;
}
