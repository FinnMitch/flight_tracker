/**
 * EventHanlder is for handling all user input, i.e. mouse presses & movements
 * It determines what unique event has happened & then runs the associated code
 * E.g. where eventNum is 1, switch to the dataScreen
 *
 * When 'Update' is pressed, takes input from dropdown menus and runs relevant methods to get flight data
 *
 * Honor 28/03/2025
 **/

class EventHandler {

  private Widget columnOptionsMenu;
  private Widget sortOptionsMenu;
  private Widget dateWidgetButton;

  //Set Widget references
  public void setWidgetVisibilityControl(Widget columnOptions, Widget sortOptions, Widget dateWidget) {
    this.columnOptionsMenu = columnOptions;
    this.sortOptionsMenu = sortOptions;
    this.dateWidgetButton = dateWidget;
  }

  public void handleMousePress(int eventNum) {
    switch (eventNum) {
    case 1:
      currentScreen = dataScreen; //Changing screens isn't complex enough to require its own method
      doSelections(); //so the bar chart opens sorted
      break;
    case 2:
      currentScreen = welcomeScreen; //Same here, extra method unnecessary
      break;
    case 3:
      // Update button: update data, use mutator method in BarChart etc
      doSelections();
      break;
    case 4:
      //dropdown menu
      for (Widget w : currentScreen.getWidgets()) {
        if (w instanceof DropDownMenu && w.getEvent() == 4) {
          System.out.println("Opening column dropdown (event 4)");
          ((DropDownMenu)w).selectOption(mouseX, mouseY);
          break; // Stop after 1st matching dropdown
        }
      }
      break;
    case 5:
      // Sorting dropdown
      for (Widget w : currentScreen.getWidgets()) {
        if (w instanceof DropDownMenu && w.getEvent() == 5) {
          System.out.println("Opening sort dropdown (event 5)");
          ((DropDownMenu)w).selectOption(mouseX, mouseY);
          break; // Stop after 1st matching dropdown
        }
      }
      break;
    case 6:
      // Show BarChart only
      setVis("Map", false);
      setVis("List", false);
      setVis("BarChart", true);

      if (columnOptionsMenu != null) columnOptionsMenu.setVisibility(true);
      if (sortOptionsMenu != null) sortOptionsMenu.setVisibility(true);
      if (dateWidgetButton != null) dateWidgetButton.setVisibility(false);
      break;
    case 7:
      // Show Map only
      setVis("BarChart", false);
      setVis("List", false);
      setVis("Map", true);

      if (columnOptionsMenu != null) columnOptionsMenu.setVisibility(false);
      if (sortOptionsMenu != null) sortOptionsMenu.setVisibility(false);
      if (dateWidgetButton != null) dateWidgetButton.setVisibility(false);

      break;
    case 8:
      // Show List only
      setVis("BarChart", false);
      setVis("Map", false);
      setVis("List", true);

      if (columnOptionsMenu != null) columnOptionsMenu.setVisibility(false);
      if (sortOptionsMenu != null) sortOptionsMenu.setVisibility(true);
      if (dateWidgetButton != null) dateWidgetButton.setVisibility(true);
      break;
    case 9:
      // Main Filter dropdown
      FindAndHandleFilterDropdown();
      break;
    case 10:
      // Apply Filters button
      FindAndHandleApplyFilters();
      break;
    case 11:
      // Reset Filters button
      FindAndHandleResetFilters();
      break;
    case 12:
      if (dateWidgetButton.getVisibility()) {
        sortFilter.sortByDate();
        for (Display d : currentScreen.getDisplays()) {
          if (d instanceof List) {
            List listDisplay = (List)d;
            listDisplay.setSortMethod("Date");
            listDisplay.updateDisplay(sortFilter.filteredData);
          }
        }
      }
      break;
    default:
      break;
    }
  }

  public void handleMouseHover(int eventNum) { //Currently not implemented, dropdown menus toggle up & down instead
    currentScreen.checkHover();
    //  switch (eventNum) {
    //  default:
    //    break;
    //  }

    currentScreen.checkHover();
  }

  public void setVis(String whichDisplay, boolean visible) {
    ArrayList<Display> displays = currentScreen.getDisplays();
    for (Display d : displays) {
      if ((whichDisplay.equals("BarChart") && d instanceof BarChart) ||
        (whichDisplay.equals("Map") && d instanceof Map) ||
        (whichDisplay.equals("List") && d instanceof List)) {
        d.setVisibility(visible);
      }
    }
  }

  /* private void handleDropdownClick(int eventNum) {
   // match eventNum & click for options
   for (Widget w : currentScreen.getWidgets()) {
   if (w.getEvent() == eventNum && w instanceof DropDownMenu) {
   ((DropDownMenu)w).selectOption(mouseX, mouseY);
   break;
   }
   }
   }
   */
  private void doSelections() {
    // Get selected options from the dropdowns
    String columnOption = "";
    String listSortOption = "";
    FilterDropdown filterDropdown = null;

    // Retrieve selected options from the dropdowns
    for (Widget w : currentScreen.getWidgets()) {
      if (w instanceof DropDownMenu) {
        DropDownMenu ddm = (DropDownMenu)w;
        int eventId = ddm.getEvent();
        if (eventId == 4) {
          columnOption = ddm.getSelectedOption();
        } else if (eventId == 5) {
          listSortOption = ddm.getSelectedOption();
        }
      } else if (w instanceof FilterDropdown && w.getVisibility()) {
        filterDropdown = (FilterDropdown)w;
      }
    }

    // apply selected column
    String realColumn = "";
    if (!columnOption.isEmpty()) {
      realColumn = changeColumnName(columnOption);
    } else {
      // Default column if none selected
      realColumn = "DEST_STATE_ABR";
    }

    // Track which sort method is being used for ListView
    String listSortMethod = "None";
    // Always apply frequency sorting for the selected column for BarChart
    if (realColumn.length() > 0) {
      // Apply frequency-based sorting on the selected column
      sortFilter.sortByFrequency(realColumn);
    }

    // sorting for List; print statements for debugging
    if (listSortOption.equals("Lateness")) {
      sortFilter.sortByLateness();
      listSortMethod = "Lateness";
      println("Sorting List by lateness status");
    } else if (listSortOption.equals("Distance")) {
      sortFilter.sortByDistance();
      listSortMethod = "Distance";
      println("Sorting List by flight distance");
    } else if (listSortOption.equals("Flight Date")) {
      sortFilter.sortByDate();
      listSortMethod = "Date";
      println("Sorting List by flight date");
    } else if (listSortOption.equals("Frequency")) {
      listSortMethod = "Frequency";
      println("Keeping frequency sort for list");
    } else {
      println("Using frequency sorting by default");
    }

    // Update all displays
    ArrayList<Display> displays = currentScreen.getDisplays();
    for (Display d : displays) {
      if (d instanceof BarChart) {
        // update BarCHart with selected column
        BarChart bc = (BarChart)d;
        bc.setValueType(listSortMethod);

        // set display column
        if (!columnOption.isEmpty()) {
          bc.setColumn(realColumn);
        }
        // update bar chart
        bc.updateChart(sortFilter.filteredData);
      } else if (d instanceof List) {
        // update List with  sorted data
        List l = (List)d;

        // sortMethod (used for labels etc)
        l.setSortMethod(listSortMethod);

        // update
        l.updateDisplay(sortFilter.filteredData);

        // update column
        if (!columnOption.isEmpty()) {
          l.setColumn(realColumn);
        }
      } else if (d instanceof Map) {
        //have to specify below since we need Map methods not just Display methods
        Map mapDisplay = (Map)d;
        mapDisplay.setTable(sortFilter.filteredData);
      }
    }
  }

  private String changeColumnName(String betterName) {
    switch(betterName) {
    case "Destination State":
      return "DEST_STATE_ABR";
    case "Origin State":
      return "ORIGIN_STATE_ABR";
    case "Airline":
      return "MKT_CARRIER";
    case "Departure Airport":
      return "ORIGIN";
    case "Arrival Airport":
      return "DEST";
    case "Flight Date":
      return "FL_DATE";
    default:
      return "DEST_STATE_ABR";
    }
  }
  private void FindAndHandleFilterDropdown() {
    for (Widget w : currentScreen.getWidgets()) {
      if (w instanceof FilterDropdown) {
        FilterDropdown fd = (FilterDropdown)w;
        fd.handleClick(mouseX, mouseY);
        return;
      }
    }
  }

  private void FindAndHandleApplyFilters() {
    for (Widget w : currentScreen.getWidgets()) {
      if (w instanceof FilterDropdown) {
        FilterDropdown fd = (FilterDropdown)w;
        fd.applyFilters();
        doSelections(); // Update displays with filtered data
        return;
      }
    }
  }

  private void FindAndHandleResetFilters() {
    for (Widget w : currentScreen.getWidgets()) {
      if (w instanceof FilterDropdown) {
        FilterDropdown fd = (FilterDropdown)w;
        fd.resetFilters();
        doSelections(); // Update displays with unfiltered data
        return;
      }
    }
  }
}
/*
 * 1 = to dataScreen
 * 2 = to welcomeScren
 * 3 = go! / update data
 * 4 = dropdown menu
 * 5 = bar chart view
 * 6 = map view
 *
 * Added cases for update button, dropdown menu
 */
