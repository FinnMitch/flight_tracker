/* //<>//
 * Widget with extra nested dropdown functions for filtering options
 * Chloe 7/4/25
 */

class FilterDropdown extends Widget {
  private ArrayList<String> categories;
  private HashMap<String, ArrayList<String>> options;
  private String selectedCategory = "";
  private HashMap<String, String> selectedOptions;
  private HashMap<String, ArrayList<String>> multiSelectedOptions;
  private boolean showCategories = false;
  private boolean showOptions = false;
  private final int PADDING = 5;
  private int optionHeight = 30;
  private PFont widgetFont;
  private boolean filtersActive = false;
  private String endDateSelection = "";
  private int scrollPosition = 0;

  //Constructor
  public FilterDropdown(int x, int y, int width, int optionHeight, PFont widgetFont, int event) {
    super(x, y, width, optionHeight, event);
    this.optionHeight = optionHeight;
    this.widgetFont = widgetFont;

    categories = new ArrayList<String>();
    options = new HashMap<String, ArrayList<String>>();
    selectedOptions = new HashMap<String, String>(); //Can select multiple, which are stored as a hashmap
    multiSelectedOptions = new HashMap<String, ArrayList<String>>();

    categories.add("Date Range");
    categories.add("Origin Airport");
    categories.add("Dest Airport");
    categories.add("Destination");

    // Gets initial settings from object sortFilter of class SortAndFilter, declared in G24
    initializeFilterOptions();
  }

  private void initializeFilterOptions() {
    // start & end dates
    ArrayList<String> dates = sortFilter.getUniqueDates();
    options.put("Date Range", dates);


    // Origin Airport & Dest Airport
    ArrayList<String> airports = sortFilter.getUniqueAirports();

    options.put("Origin Airport", airports);
    options.put("Dest Airport", airports);

    ArrayList<String> destCities = new ArrayList<String>();
    destCities.add("");
    java.util.HashSet<String> citySet = new java.util.HashSet<String>();

    for (TableRow row : sortFilter.originalData.rows()) {
      String city = row.getString("DEST_CITY_NAME");
      if (city != null && !city.isEmpty() && !citySet.contains(city)) {
        citySet.add(city);
        destCities.add(city);
      }
    }

    // using Collections sort() to make alphabetical
    if (destCities.size() > 1) {
      java.util.Collections.sort(destCities.subList(1, destCities.size()));
    }
    options.put("Destination", destCities);

    // Initialize selected options to empty strings
    for (String category : categories) {
      selectedOptions.put(category, "");
      multiSelectedOptions.put(category, new ArrayList<String>());
    }
  }

  @Override
    public void draw() {
    textFont(widgetFont);
    textAlign(LEFT, CENTER);

    fill(150, 195, 255);
    stroke(0);
    rect(x, y, width, optionHeight, 5);
    fill(0);
    String mainLabel = "Filter";
    if (filtersActive) {
      mainLabel += " (On)";
    }
    text(mainLabel, x + PADDING, y + optionHeight/2);
    fill(50, 80, 120);
    triangle(x + width - 15, y + 10, x + width - 5, y + 10, x + width - 10, y + 20);

    if (showCategories) {
      int categoriesHeight = categories.size() * optionHeight;
      fill(27, 36, 82, 240);
      stroke(200, 200, 255);
      rect(x, y + optionHeight, width, categoriesHeight, 5);

      for (int i = 0; i < categories.size(); i++) {
        if (categories.get(i).equals(selectedCategory)) {
          fill(150, 195, 255);
          rect(x, y + (i+1)*optionHeight, width, optionHeight);
          fill(255);
        } else {
          fill(255);
        }

        text(categories.get(i), x + PADDING, y + (i+1)*optionHeight + optionHeight/2);
        // show options in right context
        if (showOptions && categories.get(i).equals(selectedCategory)) {
          ArrayList<String> categoryOptions = options.get(selectedCategory);

          if (categoryOptions != null && !categoryOptions.isEmpty()) {
            int optionsX = x + width + 10;
            int optionsY = y + optionHeight;

            int optionCount = categoryOptions.size();
            //show 20 options at a time
            int maxOptionsToShow = min(optionCount, 20);
            int optionsHeight = maxOptionsToShow * optionHeight;

            fill(40, 50, 100, 240);
            stroke(200, 200, 255);
            rect(optionsX, optionsY, width * 1.5, optionsHeight, 5);

            // what's visible in scroll
            int startIdx = scrollPosition;
            int endIdx = min(startIdx + maxOptionsToShow, optionCount);
            fill(255);
            for (int j = 0; j < (endIdx - startIdx); j++) {
              int dataIndex = j + startIdx;
              String option = categoryOptions.get(dataIndex);
              boolean isSelected = false;
              if (selectedCategory.equals("Date Range")) {
                isSelected = option.equals(selectedOptions.get(selectedCategory)) ||
                  option.equals(endDateSelection);
              } else if (selectedCategory.equals("Origin Airport") ||
                selectedCategory.equals("Dest Airport")) {
                // For airports: check multi-selection list
                isSelected = multiSelectedOptions.get(selectedCategory).contains(option);
              } else {
                isSelected = option.equals(selectedOptions.get(selectedCategory));
              }

              if (isSelected) {
                fill(150, 195, 255);
                rect(optionsX, optionsY + j*optionHeight, width * 1.5, optionHeight);
                fill(255);
              }
              text(option, optionsX + PADDING, optionsY + j*optionHeight + optionHeight/2);
            }

            // Draw scroll indicators if needed
            if (optionCount > maxOptionsToShow) {
              // Up scroll arrow
              if (scrollPosition > 0) {
                fill(200, 200, 255);
                triangle(
                  optionsX + width * 1.5 - 15, optionsY + 15,
                  optionsX + width * 1.5 - 5, optionsY + 15,
                  optionsX + width * 1.5 - 10, optionsY + 5
                  );
              }

              // Down scroll arrow
              if (scrollPosition + maxOptionsToShow < optionCount) {
                fill(200, 200, 255);
                triangle(
                  optionsX + width * 1.5 - 15, optionsY + optionsHeight - 15,
                  optionsX + width * 1.5 - 5, optionsY + optionsHeight - 15,
                  optionsX + width * 1.5 - 10, optionsY + optionsHeight - 5
                  );
              }

              // Draw scrollbar
              float scrollbarHeight = map(maxOptionsToShow, 0, optionCount, 0, optionsHeight);
              float scrollbarY = map(scrollPosition, 0, optionCount - maxOptionsToShow, 0, optionsHeight - scrollbarHeight);

              fill(100, 100, 150, 180);
              rect(optionsX + width * 1.5 - 8, optionsY + scrollbarY, 5, scrollbarHeight);
            }
          }
        }
      }

      if (filtersActive) {
        int filterSummaryY = y + optionHeight + categoriesHeight + 10;

        // Calculate summary box based on selected filters
        int summaryHeight = optionHeight * 4;

        // Check for airport selections, might need more space
        int airportLines = 0;
        for (String airportType : new String[]{"Origin Airport", "Dest Airport"}) {
          ArrayList<String> airports = multiSelectedOptions.get(airportType);
          if (airports != null && !airports.isEmpty()) {
            // Add one line for category label, plus additional lines for the airports; 1 line per 3 airports, rounded
            airportLines += 1 + ceil(airports.size() / 3.0);
          }
        }
        summaryHeight += optionHeight * airportLines;
        fill(60, 90, 140, 235);
        rect(x, filterSummaryY, width * 1.5, summaryHeight, 5);

        fill(255);
        int line = 1;
        for (String category : categories) {
          String value = selectedOptions.get(category);
          ArrayList<String> multiValues = multiSelectedOptions.get(category);

          if (category.equals("Date Range") && value != null && !value.isEmpty() && !endDateSelection.isEmpty()) {
            // format date display so it fits
            text(category + ":", x + PADDING, filterSummaryY + line*optionHeight);
            String dateText = value + " - " + endDateSelection;

            textSize(14); // smaller so it fits
            text(dateText, x + PADDING, filterSummaryY + (line+1)*optionHeight);
            textSize(14);
            line += 2;
          } else if ((category.equals("Origin Airport") || category.equals("Dest Airport"))
            && multiValues != null && !multiValues.isEmpty()) {
            // Format airport display
            text(category + ":", x + PADDING, filterSummaryY + line*optionHeight);
            line++;

            textSize(14); // smaller so it fits

            String airportText = "";
            int count = 0;
            for (String airport : multiValues) {
              if (count > 0) airportText += ", ";
              airportText += airport;
              count++;

              //line break after every 3 airports
              if (count % 3 == 0 && count < multiValues.size()) {
                text(airportText, x + PADDING, filterSummaryY + line*optionHeight);
                line++;
                airportText = "";
                count = 0;
              }
            }
            if (!airportText.isEmpty()) {
              text(airportText, x + PADDING, filterSummaryY + line*optionHeight);
              line++;
            }

            textSize(14);
          } else if (!category.equals("Date Range") && !category.equals("Origin Airport") &&
            !category.equals("Dest Airport") &&
            value != null && !value.isEmpty()) {
            text(category + ": " + value,
              x + PADDING, filterSummaryY + line*optionHeight);
            line++;
          }
        }

        // apply & reset buttons (variable height)
        int buttonsY = filterSummaryY + summaryHeight;
        fill(40, 50, 100);
        rect(x, buttonsY, width * 0.7, optionHeight, 5);
        fill(255);
        textAlign(CENTER, CENTER);
        text("Apply", x + width * 0.35, buttonsY + optionHeight/2);

        fill(40, 45, 60);
        rect(x + width * 0.8, buttonsY, width * 0.7, optionHeight, 5);
        fill(255);
        text("Reset", x + width * 1.15, buttonsY + optionHeight/2);

        textAlign(LEFT, CENTER);
      }
    }
  }

  @Override
    public int getEvent(int mx, int my) {
    // Main filter button clicked
    if (mx > x && mx < x + width && my > y && my < y + optionHeight) {
      return event;
    }

    // Apply button
    if (showCategories && filtersActive) {
      int filterSummaryY = y + optionHeight + categories.size() * optionHeight + 10;

      // Calculate summary height for button positioning
      int summaryHeight = optionHeight * 4;
      int airportLines = 0;

      for (String airportType : new String[]{"Origin Airport", "Dest Airport"}) {
        ArrayList<String> airports = multiSelectedOptions.get(airportType);
        if (airports != null && !airports.isEmpty()) {
          airportLines += 1 + ceil(airports.size() / 3.0);
        }
      }
      summaryHeight += optionHeight * airportLines;
      int buttonsY = filterSummaryY + summaryHeight;

      if (mx > x && mx < x + width * 0.7 &&
        my > buttonsY && my < buttonsY + optionHeight) {
        return event + 1; // Apply filters (event 10)
      }

      // Reset button
      if (mx > x + width * 0.8 && mx < x + width * 1.5 &&
        my > buttonsY && my < buttonsY + optionHeight) {
        return event + 2; // Reset filters (event 11)
      }
    }
    return 0;
  }

  public void handleClick(int mx, int my) {
    // println("FilterDropdown.handleClick at x=" + mx + ", y=" + my);

    // Toggle main dropdown
    if (mx > x && mx < x + width && my > y && my < y + optionHeight) {
      showCategories = !showCategories;
      // Close options from closing main dropdown
      if (!showCategories) {
        showOptions = false;
        selectedCategory = "";
        scrollPosition = 0; // Reset scroll position when closing dropdown
      }
      return;
    }

    // Only proceed if categories are showing
    if (!showCategories) return;

    // Check if a category was clicked
    if (mx > x && mx < x + width) {
      int categoryIndex = (my - (y + optionHeight)) / optionHeight;

      if (categoryIndex >= 0 && categoryIndex < categories.size()) {
        String clickedCategory = categories.get(categoryIndex);

        // If clicking the same category, toggle options visibility
        if (clickedCategory.equals(selectedCategory)) {
          showOptions = !showOptions;
        } else {
          // If clicking a different category, select it and show options
          selectedCategory = clickedCategory;
          showOptions = true;
          scrollPosition = 0; // Reset scroll position when changing category
        }

      //  println("Category clicked: " + selectedCategory + ", showOptions=" + showOptions);
        return;
      }
    }

    // Check if an option was clicked
    if (showOptions && !selectedCategory.isEmpty()) {
      int optionsX = x + width + 10;
      int optionsY = y + optionHeight;
      int optionWidth = (int)(width * 1.5);
      ArrayList<String> categoryOptions = options.get(selectedCategory);

      if (categoryOptions == null || categoryOptions.isEmpty()) return;

      int optionCount = categoryOptions.size();
      int maxOptionsToShow = min(optionCount, 20);
      int optionsHeight = maxOptionsToShow * optionHeight;

     // println("Checking option click in area: x=" + optionsX + "-" + (optionsX+optionWidth) +
      //  ", y=" + optionsY + "-" + (optionsY + optionsHeight));

      // Check if scroll arrows were clicked
      if (optionCount > maxOptionsToShow && mx > optionsX + optionWidth - 20 && mx < optionsX + optionWidth) {
        // Up arrow clicked
        if (my > optionsY && my < optionsY + 20 && scrollPosition > 0) {
          scrollPosition = max(0, scrollPosition - 5); // Scroll up 5 items
        //  println("Scrolled up to position " + scrollPosition);
          return;
        }

        // Down arrow clicked
        if (my > optionsY + optionsHeight - 20 && my < optionsY + optionsHeight &&
          scrollPosition < optionCount - maxOptionsToShow) {
          scrollPosition = min(scrollPosition + 5, optionCount - maxOptionsToShow); // Scroll down 5 items
        //  println("Scrolled down to position " + scrollPosition);
          return;
        }
      }

      // Check if an option was clicked
      if (mx > optionsX && mx < optionsX + optionWidth - 20) { // Leave space for scrollbar
        int optionIndex = (my - optionsY) / optionHeight;

        if (optionIndex >= 0 && optionIndex < maxOptionsToShow) {
          int actualIndex = optionIndex + scrollPosition;

          if (actualIndex < categoryOptions.size()) {
            String selectedOption = categoryOptions.get(actualIndex);
            // println("Option clicked: " + selectedOption);

            // Handle Date Range special case (needs start and end dates)
            if (selectedCategory.equals("Date Range")) {
              if (selectedOptions.get(selectedCategory).isEmpty()) {
                // First click sets start date
                selectedOptions.put(selectedCategory, selectedOption);
                // println("Set start date: " + selectedOption);
              } else {
                // Second click sets end date and closes options
                endDateSelection = selectedOption;
                showOptions = false;
                // println("Set end date: " + selectedOption);
              }
            }
            // Handle Airport - allow multiple selections
            else if (selectedCategory.equals("Origin Airport") ||
              selectedCategory.equals("Dest Airport")) {
              ArrayList<String> selectedAirports = multiSelectedOptions.get(selectedCategory);

              // If option is blank, clear all selections
              if (selectedOption.isEmpty()) {
                selectedAirports.clear();
                selectedOptions.put(selectedCategory, "");
                // println("Cleared " + selectedCategory + " selections");
              }
              // Toggle the airport selection
              else if (selectedAirports.contains(selectedOption)) {
                selectedAirports.remove(selectedOption);
                // println("Removed " + selectedCategory + ": " + selectedOption);
              } else {
                selectedAirports.add(selectedOption);
                // println("Added " + selectedCategory + ": " + selectedOption);
              }

              // Only close the options if there's no selection (otherwise keep open)
              if (selectedAirports.isEmpty() && selectedOption.isEmpty()) {
                showOptions = false;
              }
            } else {
              // For other categories, just set the selection and close options
              selectedOptions.put(selectedCategory, selectedOption);
              showOptions = false;
              // println("Set " + selectedCategory + " to: " + selectedOption);
            }

            updateFiltersActiveState();
            return;
          }
        }
      }
    }

    // Check for Apply/Reset buttons if filters are active
    if (filtersActive) {
      int filterSummaryY = y + optionHeight + categories.size() * optionHeight + 10;

      // Calculate summary height for button positioning
      int summaryHeight = optionHeight * 4;
      int airportLines = 0;
      for (String airportType : new String[]{"Origin Airport", "Dest Airport"}) {
        ArrayList<String> airports = multiSelectedOptions.get(airportType);
        if (airports != null && !airports.isEmpty()) {
          airportLines += 1 + ceil(airports.size() / 3.0);
        }
      }
      summaryHeight += optionHeight * airportLines;
      int buttonsY = filterSummaryY + summaryHeight;

      // Apply button
      if (mx > x && mx < x + width * 0.7 &&
        my > buttonsY && my < buttonsY + optionHeight) {
        // println("Apply button clicked directly");
        applyFilters();
        // Trigger doSelections to update visualizations
        eventHandler.doSelections();
        return;
      }

      // Reset button
      if (mx > x + width * 0.8 && mx < x + width * 1.5 &&
        my > buttonsY && my < buttonsY + optionHeight) {
        // println("Reset button clicked directly");
        resetFilters();
        // update visuals
        eventHandler.doSelections();
        return;
      }
    }
  }

  // scrolling through options
  public void handleWheel(int e) {
    if (showOptions && !selectedCategory.isEmpty()) {
      ArrayList<String> categoryOptions = options.get(selectedCategory);

      if (categoryOptions != null && categoryOptions.size() > 20) {
        int optionCount = categoryOptions.size();
        int maxScrollPosition = optionCount - 20;

        // e = positive for scrolling down, - for scrolling up
        scrollPosition = constrain(scrollPosition + e, 0, maxScrollPosition);
        // println("Scrolled to position " + scrollPosition);
      }
    }
  }

  private void updateFiltersActiveState() {
    filtersActive = false;

    // filters selected?
    for (String category : categories) {
      String value = selectedOptions.get(category);
      ArrayList<String> multiValues = multiSelectedOptions.get(category);

      if (value != null && !value.isEmpty()) {
        if (category.equals("Date Range")) {
          // both start & end dates needed
          if (!endDateSelection.isEmpty()) {
            filtersActive = true;
            break;
          }
        } else {
          filtersActive = true;
          break;
        }
      }
      // Check multi-selections (for airports)
      else if (multiValues != null && !multiValues.isEmpty()) {
        filtersActive = true;
        break;
      }
    }

    // println("Updated filters active state: " + filtersActive);
  }

  public void applyFilters() {
    sortFilter.resetFilters();

    // do active filters
    for (String category : categories) {
      String value = selectedOptions.get(category);
      if (value != null && !value.isEmpty()) {
        if (category.equals("Date Range") && !endDateSelection.isEmpty()) {
          sortFilter.setDateFilter(value, endDateSelection);
          // println("Applied date filter: " + value + " to " + endDateSelection);
        } else if (category.equals("Destination")) {
          sortFilter.setDestCityFilter(value);
          // println("Applied destination city filter: " + value);
        }
      }

      // multi-selections for airport types
      if (category.equals("Origin Airport") || category.equals("Dest Airport")) {
        ArrayList<String> airports = multiSelectedOptions.get(category);
        if (airports != null && !airports.isEmpty()) {
          if (category.equals("Origin Airport")) {
            sortFilter.setDepartureAirportFilter(airports);
            // println("Applied departure airport filter with " + airports.size() + " airports");
          } else { // Dest Airport
            sortFilter.setArrivalAirportFilter(airports);
            // println("Applied arrival airport filter with " + airports.size() + " airports");
          }
        }
      }
    }

    showCategories = false;
    showOptions = false;
  }

  public void resetFilters() {
    // println("Resetting all filters");

    // Clear selected
    for (String category : categories) {
      selectedOptions.put(category, "");
      multiSelectedOptions.get(category).clear();
    }
    endDateSelection = "";
    filtersActive = false;
    sortFilter.resetFilters();

    showCategories = false;
    showOptions = false;
    scrollPosition = 0;
  }

  //getters to allow mousePressed to access
  public int getX() {
    return x;
  }

  public int getY() {
    return y;
  }

  public int getWidth() {
    return width;
  }

  public int getHeight() {
    return optionHeight;
  }
}
