/*
 * Based off of Tanmayee's query system & filtering structures
 * Integrated by Chloe
 * Handles vast majority of data processing; includes filtering by variety of options; sorting by variety of options,
 * including multiselection options. Interacts mainly with EventHandler and FilterDropdown
 */
 
class SortAndFilter {
  Table originalData;
  Table filteredData;

  String startDate = "";
  String endDate = "";
  String airportCode = "";
  String destCity = "";
  boolean filterByDate = false;
  boolean filterByDestCity = false;
  boolean filterByDateHighToLow = false;

  ArrayList<String> departureAirports = new ArrayList<String>();
  ArrayList<String> arrivalAirports = new ArrayList<String>();
  boolean filterByDepartureAirport = false;
  boolean filterByArrivalAirport = false;

  public SortAndFilter(Table originalTable) {
    originalData = originalTable.copy();
    filteredData = originalTable.copy();
    //NOTE: Removed the copyTable(source, destination) method since Table class already has inbuilt copy() method. HM
  }

  void setDateFilter(String start, String end) {
    startDate = start;
    endDate = end;
    filterByDate = (startDate.length() > 0 && endDate.length() > 0);
    applyFilters();
  }

  void setDestCityFilter(String city) {
    destCity = city.trim();
    filterByDestCity = (destCity.length() > 0);
    applyFilters();
  }

  void setDepartureAirportFilter(ArrayList<String> airports) {//Changed so that departure airports is a new ArrayList here
    // departure filter flag
    filterByDepartureAirport = (airports.size() > 0);
    departureAirports = (ArrayList<String>) airports.clone();

    applyFilters();
  }

  void setArrivalAirportFilter(ArrayList<String> airports) {
    // arrival filter flag
    filterByArrivalAirport = (airports.size() > 0);
    arrivalAirports = (ArrayList<String>) airports.clone();

    applyFilters();
  }

  void DateHighToLowSort() {
    filterByDateHighToLow = true;
    applyFilters();
  }

  void resetFilters() {
    startDate = "";
    endDate = "";
    airportCode = "";
    destCity = "";
    filterByDate = false;

    //filterByAirport = false;
    filterByDestCity = false;

    departureAirports.clear();
    arrivalAirports.clear();
    filterByDepartureAirport = false;
    filterByArrivalAirport = false;

    filteredData = new Table();
    filteredData = originalData.copy();
  }

  // new filtered table
  void applyFilters() {
    filteredData = originalData.copy();


    // if active, do date filter (& cont w/ repsective filters below)
    if (filterByDate) {
      applyDateFilter();
    }

    if (filterByDepartureAirport) {
      applyDepartureAirportFilter();
    }

    if (filterByArrivalAirport) {
      applyArrivalAirportFilter();
    }

    if (filterByDestCity) {
      applyDestCityFilter();
    }

    if (filterByDateHighToLow) {
      filterByDate();
    }
  }

  private void filterByDate() {
    filteredData.sort("FL_DATE");

    Table reversedTable = new Table();

    for (int i = 0; i < filteredData.getColumnCount(); i++) {
      reversedTable.addColumn(filteredData.getColumnTitle(i));
    }

    for (int i = filteredData.getRowCount() - 1; i >= 0; i--) {
      TableRow srcRow = filteredData.getRow(i);
      TableRow newRow = reversedTable.addRow();

      for (int j = 0; j < filteredData.getColumnCount(); j++) {
        String colName = filteredData.getColumnTitle(j);
        newRow.setString(colName, srcRow.getString(colName));
      }
    }

    filteredData = reversedTable;

    for (int i = 0; i < min(5, filteredData.getRowCount()); i++) {
      TableRow row = filteredData.getRow(i);
    }
  }

  private void applyDateFilter() {
    Table tempTable = new Table();

    // Copy column structure
    tempTable.setColumnTitles(filteredData.getColumnTitles());
    tempTable.setColumnTypes(filteredData.getColumnTypes());

    for (TableRow row : filteredData.rows()) {
      String dateStr = row.getString("FL_DATE");

      // only use if date is within range
      if (isDateInRange(dateStr, startDate, endDate)) {
        tempTable.addRow(row);
      }
    }

    filteredData = tempTable.copy();
  }

  private void applyDepartureAirportFilter() {
    if (departureAirports == null || departureAirports.isEmpty()) return;

    Table tempTable = new Table();

    tempTable.setColumnTitles(filteredData.getColumnTitles()); //Replaces for-loop with inbuilt Table methods HM
    tempTable.setColumnTypes(filteredData.getColumnTypes());

    for (TableRow row : filteredData.rows()) {
      String origin = row.getString("ORIGIN");

      // origin airport matches in our list? include
      boolean matchFound = false;
      for (String code : departureAirports) {
        code = code.trim().toUpperCase();
        if (origin.equals(code)) {
          matchFound = true;
          break;
        }
      }

      if (matchFound) {

        tempTable.addRow(row);
      }
    }

    //Changed so that filteredData is a completely new table and not just a new reference to tempTable HM
    filteredData = tempTable.copy();
  }

  private void applyArrivalAirportFilter() { //Same edits made to this as applyDepartureAirportFilter()
    if (arrivalAirports == null || arrivalAirports.isEmpty()) return;

    Table tempTable = new Table();
    tempTable.setColumnTitles(filteredData.getColumnTitles());
    tempTable.setColumnTypes(filteredData.getColumnTypes());

    // filter rows by arrival airports
    for (TableRow row : filteredData.rows()) {
      String dest = row.getString("DEST");

      // Include if dest airport matches in our list
      boolean matchFound = false;
      for (String code : arrivalAirports) {
        code = code.trim().toUpperCase();
        if (dest.equals(code)) {
          matchFound = true;
          break;
        }
      }

      if (matchFound) {

        tempTable.addRow(row);
      }
    }
    filteredData = tempTable.copy();
  }

  private void applyDestCityFilter() {
    Table tempTable = new Table();

    tempTable.setColumnTitles(filteredData.getColumnTitles());
    tempTable.setColumnTypes(filteredData.getColumnTypes());

    for (TableRow row : filteredData.rows()) {
      String city = row.getString("DEST_CITY_NAME");

      // destination city matches? include
      if (city.equals(destCity)) {
        tempTable.addRow(row);
      }
    }
    filteredData = tempTable.copy();
  }

  // Check if date is within our range
  private boolean isDateInRange(String dateStr, String startDateStr, String endDateStr) {
    if (dateStr == null || dateStr.isEmpty()) {
      return false;
    }

    try {
      return (dateStr.compareTo(startDateStr) >= 0 &&
        dateStr.compareTo(endDateStr) <= 0);
    }
    catch (Exception e) {
      println("Error comparing dates: " + e.getMessage());
      return false;
    }
  }

  void sortByFrequency(String columnName) {
    IntDict valueCounts = new IntDict();
    for (TableRow row : filteredData.rows()) {
      String value = row.getString(columnName);
      if (value != null && !value.trim().isEmpty()) {
        valueCounts.increment(value);
      }
    }
    valueCounts.sortValuesReverse();

    Table sortedTable = new Table();

    for (int i = 0; i < filteredData.getColumnCount(); i++) {
      sortedTable.addColumn(filteredData.getColumnTitle(i));
    }
    for (String value : valueCounts.keyArray()) {
      for (TableRow row : filteredData.rows()) {
        if (value.equals(row.getString(columnName))) {
          TableRow newRow = sortedTable.addRow();
          for (int i = 0; i < filteredData.getColumnCount(); i++) {
            String colName = filteredData.getColumnTitle(i);
            newRow.setString(colName, row.getString(colName));
          }
        }
      }
    }
    filteredData = sortedTable.copy();
  }

  // Sort by lateness - use"LATE" column from main
  void sortByLateness() {
    if (!columnExists(filteredData, "latenessNum")) {
      filteredData.addColumn("latenessNum", Table.INT);
    }

    // Convert to int for sorting
    for (TableRow row : filteredData.rows()) {
      String lateStr = row.getString("LATE");
      int latenessValue;

      if (lateStr == null || lateStr.isEmpty() || lateStr.equals("N/A")) {
        latenessValue = -8000;  // Missing data
      } else if (lateStr.equals("[cancelled]")) {
        latenessValue = -9000;  // Cancelled flights
      } else {
        try {
          latenessValue = Integer.parseInt(lateStr);
        }
        catch (NumberFormatException e) {
          latenessValue = -8000;
        }
      }

      row.setInt("latenessNum", latenessValue);
    }

    // Sort table by latenessNum column (descending)
    filteredData.sortReverse("latenessNum");
  }

  boolean columnExists(Table table, String columnName) {
    for (int i = 0; i < table.getColumnCount(); i++) {
      if (table.getColumnTitle(i).equals(columnName)) {
        return true;
      }
    }
    return false;
  }

  void sortByDistance() {
    // set DISTANCE column type to INT
    filteredData.setColumnType("DISTANCE", Table.INT);
    filteredData.sortReverse("DISTANCE");
  }

  void sortByDate() {
    // reverse to get newest first
    filteredData.sort("FL_DATE");

    Table reversedTable = new Table();

    // Copy column structure
    for (int i = 0; i < filteredData.getColumnCount(); i++) {
      reversedTable.addColumn(filteredData.getColumnTitle(i));
    }

    // newest rows added first
    for (int i = filteredData.getRowCount() - 1; i >= 0; i--) {
      TableRow srcRow = filteredData.getRow(i);
      TableRow newRow = reversedTable.addRow();

      // copy everything in column
      for (int j = 0; j < filteredData.getColumnCount(); j++) {
        String colName = filteredData.getColumnTitle(j);
        newRow.setString(colName, srcRow.getString(colName));
      }
    }

    filteredData = reversedTable.copy();
  }

  // Get list of all unique airports for dropdown
  ArrayList<String> getUniqueAirports() {
    ArrayList<String> airports = new ArrayList<String>();
    airports.add("");

    // temp for what airports already added
    java.util.HashSet<String> airportSet = new java.util.HashSet<String>();

    // origin airports
    for (TableRow row : originalData.rows()) {
      String code = row.getString("ORIGIN");
      if (code != null && !code.isEmpty() && !airportSet.contains(code)) {
        airportSet.add(code);
        airports.add(code);
      }
    }

    // destination airports
    for (TableRow row : originalData.rows()) {
      String code = row.getString("DEST");
      if (code != null && !code.isEmpty() && !airportSet.contains(code)) {
        airportSet.add(code);
        airports.add(code);
      }
    }

    // Collections sort() for alphabetical airports
    //this type of sort because Processing doesn't handle as wide of a range of data for this method
    java.util.Collections.sort(airports.subList(1, airports.size()));

    return airports;
  }

  // list of all unique dates for filling the date filter
  ArrayList<String> getUniqueDates() {
    ArrayList<String> dates = new ArrayList<String>();
    dates.add("");

    // temp for what dates already added
    java.util.HashSet<String> dateSet = new java.util.HashSet<String>();

    // Add all dates
    for (TableRow row : originalData.rows()) {
      String date = row.getString("FL_DATE");
      if (date != null && !date.isEmpty() && !dateSet.contains(date)) {
        dateSet.add(date);
        dates.add(date);
      }
    }

    // sort dates
    //this type of sort because Processing doesn't handle as wide of a range of data for this method
    java.util.Collections.sort(dates.subList(1, dates.size()));

    return dates;
  }

  // list of all unique destination cities for dropdown
  ArrayList<String> getUniqueDestCities() {
    ArrayList<String> cities = new ArrayList<String>();
    cities.add("");
    // temp for what cities already added
    java.util.HashSet<String> citySet = new java.util.HashSet<String>();

    for (TableRow row : originalData.rows()) {
      String city = row.getString("DEST_CITY_NAME");
      if (city != null && !city.isEmpty() && !citySet.contains(city)) {
        citySet.add(city);
        cities.add(city);
      }
    }

    // Collections sort() for alphabetical cities
    java.util.Collections.sort(cities.subList(1, cities.size()));

    return cities;
  }
}
/**
 * Separated sorting, filtering class so event handler doesn't get too big
 * Chloe 7/4/25
 **/
