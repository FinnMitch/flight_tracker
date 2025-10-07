/**
 * Map class written by Larisa
 *
 * Integrated by Honor
 *
 * Further integrated by Chloe: included integration of functions & modified map and coordinates to use
 * Web Mercator projection
 * Changed background rectangle to bounding box for zooming, clicking, and dragging.
 * Fixed issue with flight paths outside of continental US! Data for them is still included in
 * info given, but they no longer have flight paths leading off screen. (changes as of 9/4/25)
 *
 * Further minor UI changes 10/4/25 -CD
 **/

class Map extends Display {
  //Attributes
  PImage mapImage;
  float offsetX = 0, offsetY = 0;
  float zoomTarget = 1.0;
  float zoom = 1.0;
  float lastMouseX, lastMouseY;
  boolean dragging = false;
  String selectedAirline = "";  // Empty = show all airlines
  String selectedState = null;  // Currently clicked state name
  Airport hoveredAirport = null;
  Airport selectedAirport = null;
  // Lists to store airports, and states
  ArrayList<Airport> airports = new ArrayList<Airport>();
  ArrayList<State> states = new ArrayList<State>();

  // Constants for the Web Mercator projection
  // These define the bounds of the visible map
  private final float MAP_WEST = -125.0;  // Max Western longitude visible on map
  private final float MAP_EAST = -66.0;   // Max Eastern longitude visible on map
  private final float MAP_NORTH = 49.5;   // Max Northern latitude visible on map
  private final float MAP_SOUTH = 25.0;   // Max Southern latitude visible on map

  //Constructor
  public Map (boolean visible, Table tableToDisplay) {
    super(visible, tableToDisplay);
    mapImage = loadImage("USMAP.png");

    loadStates();  // Load all states for labels
    calculateStatePositions();
    extractAirportsFromTable();
  }

  //Methods
  public void setTable(Table newTable) {
    super.setTable(newTable);
    extractAirportsFromTable();
  }

  @Override
    public void draw() {
    int leftMargin = 50;
    int topMargin = 180;
    int mapWidth = width - 250;
    int mapHeight = 490;

    // Calculate the drawing/ clickable area
    float drawWidth = mapWidth;
    float drawHeight = mapHeight;

    // Background for map
    fill(230, 240, 255);
    rect(leftMargin, topMargin, drawWidth, drawHeight, 5);

    // Apply zoom and pan transformations
    pushMatrix();
    clip(leftMargin, topMargin, drawWidth, drawHeight); //Constrains map to background rectangle -Chloe
    translate(leftMargin + drawWidth/2, topMargin + drawHeight/2);
    translate(offsetX, offsetY);
    scale(zoom);

    if (mapImage != null) {
      imageMode(CENTER);
      image(mapImage, 0, 0, drawWidth * .99, drawHeight * .99);
      imageMode(CORNER);
    } else {
      fill(150);
      textAlign(CENTER, CENTER);
      text("Map image not found", 0, 0);
    }

    drawFlights(drawWidth, drawHeight);
    drawAirports();
    // Uncomment below to see state positions for debugging
    // drawStateLocations();

    noClip();
    popMatrix();

    drawInfoPanel(leftMargin, topMargin, drawWidth, drawHeight); //instructions for user interaction

    // Map title
    fill(70, 90, 140);
    textSize(16);
    textAlign(CENTER, CENTER);
    int flightCount = calculateVisibleFlightCount();
    text("Flight Map (" + flightCount + " flights shown)", width/2, topMargin - 20);

    if (selectedAirport != null) {
      showAirportFlightSummary(selectedAirport, leftMargin + drawWidth - 200, topMargin + 20);
    } else if (selectedState != null) {
      drawStateInfoPanel(leftMargin + drawWidth - 200, topMargin + 20);
    }
  }

  /* Overlays mapped state locations; used for debugging to ensure correct selections areas for States by clicking
   * their abbreviations already labeled on image - Chloe 8/4/
   *  private void drawStateLocations() {
   *     for (State state : states) {
   *       fill(0, 255, 255, 100);
   *       noStroke();
   *       ellipse(state.x, state.y, 15, 15);
   *
   *       fill(255);
   *       textSize(12);
   *       text(state.abbr, state.x, state.y);
   *     }
   *   }
   */

  private void extractAirportsFromTable() {
    HashMap<String, Airport> airportMap = new HashMap<String, Airport>();

    // Process Table rows
    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      TableRow row = super.tableToDisplay.getRow(i);
      String origin = row.getString("ORIGIN");
      String destination = row.getString("DEST");

      // Add origin airport
      if (!airportMap.containsKey(origin)) {
        String originCityName = row.getString("ORIGIN_CITY_NAME");
        float lat = getLatFromCode(origin);
        float lon = getLonFromCode(origin);

        // Convert geographic coordinates to screen coordinates using Mercator projection
        float screenX = mercatorLongitudeToX(lon);
        float screenY = mercatorLatitudeToY(lat);

        airportMap.put(origin, new Airport(originCityName, origin, lat, lon, screenX, screenY));
      }

      // Add destination airport
      if (!airportMap.containsKey(destination)) {
        String destCityName = row.getString("DEST_CITY_NAME");
        float lat = getLatFromCode(destination);
        float lon = getLonFromCode(destination);

        // Convert geographic coordinates to screen coordinates using Mercator projection
        float screenX = mercatorLongitudeToX(lon);
        float screenY = mercatorLatitudeToY(lat);

        airportMap.put(destination, new Airport(destCityName, destination, lat, lon, screenX, screenY));
      }
    }

    airports.clear();
    airports.addAll(airportMap.values());
  }

  private void drawFlights(float drawWidth, float drawHeight) {
    //  int visibleFlights = 0;  // Count how many flights are shown - useful for filtering debugging -Chloe

    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      TableRow row = super.tableToDisplay.getRow(i);

      // Filter by airline if needed
      if (!selectedAirline.isEmpty() && !row.getString("MKT_CARRIER").equals(selectedAirline)) {
        continue;
      }

      String origin = row.getString("ORIGIN");
      String destination = row.getString("DEST");

      // Since the default on switch statement for lat & lon is 0; we check for that here
      // to only draw flights in the continental US -Chloe
      float originLat = getLatFromCode(origin);
      float originLon = getLonFromCode(origin);
      float destLat = getLatFromCode(destination);
      float destLon = getLonFromCode(destination);

      if (originLat != 0 && originLon != 0 && destLat != 0 && destLon != 0) {
        PVector originPos = getAirportPosition(origin);
        PVector destPos = getAirportPosition(destination);

        if (originPos.x != -1 && destPos.x != -1) {
          String airline = row.getString("MKT_CARRIER");
          stroke(getAirlineColor(airline), 150);
          drawCurvedFlightLine(originPos, destPos);
          //       visibleFlights++;  // Count displayed flights
        }
      }
    }
  }

  // Draw smooth curved flight lines
  void drawCurvedFlightLine(PVector start, PVector end) {
    strokeWeight(1);
    noFill();

    // Calculate the distance between points
    float dist = PVector.dist(start, end);

    // Adjust curvature based on distance (longer flights curve more)
    float curveHeight = dist * 0.2;

    // Get the midpoint
    float midX = (start.x + end.x) / 2;
    float midY = (start.y + end.y) / 2 - curveHeight;  // Curve upward

    beginShape();
    vertex(start.x, start.y);
    quadraticVertex(midX, midY, end.x, end.y);
    endShape();
  }

  // Assign colors to airlines
  private color getAirlineColor(String airline) {
    if (airline.equals("WN")) return color(160, 140, 170); // Southwest (violet)
    if (airline.equals("AS")) return color(235, 225, 200, 100);    // Alaska (white)
    if (airline.equals("AA")) return color(100, 20, 80);    // American Airlines (purple)
    if (airline.equals("UA")) return color(150, 190, 150);  // United Airlines (green)
    if (airline.equals("B6")) return color(75, 90, 180, 200);  // JetBlue (blue)
    if (airline.equals("HA")) return color(110, 160, 160);  // Hawaiian Airlines (teal)
    if (airline.equals("DL")) return color(130, 150, 190);  // Delta Airlines (blue)
    if (airline.equals("NK")) return color(220, 205, 150);  // Spirit Airlines (yellow)
    if (airline.equals("G4")) return color(220, 165, 130);  // Allegiant Airlines (orange)
    if (airline.equals("F9")) return color(160, 170, 130);  // Frontier Airlines (olive)
    return color(255);  // Default (White)
  }

  private void drawAirports() {
    hoveredAirport = null;

    float mapCenterX = (width - 250) / 2 + 50; // leftMargin + drawWidth/2
    float mapCenterY = 180 + 490 / 2; // topMargin + drawHeight/2

    float adjustedMouseX = (mouseX - mapCenterX - offsetX) / zoom;
    float adjustedMouseY = (mouseY - mapCenterY - offsetY) / zoom;

    /*distance between mouse location and airports:
     * if hovering over airport dot, display city name & turn airport dot yellow, gets bigger
     * if still selected not hovering, stay bigger, turn green;
     * else stays blue (before selection & after de-selection)
     */
    for (Airport airport : airports) {
      float d = dist(adjustedMouseX, adjustedMouseY, airport.x, airport.y);

      if (d < 8) {
        hoveredAirport = airport;
        fill(255, 255, 0);
        noStroke();
        ellipse(airport.x, airport.y, 10, 10);
      } else if (airport == selectedAirport) {
        fill(20, 100, 20);
        noStroke();
        ellipse(airport.x, airport.y, 10, 10);
      } else {
        fill(70, 90, 140);
        noStroke();
        ellipse(airport.x, airport.y, 4, 4);
      }
    }

    // Show city name when hovering over airport
    if (hoveredAirport != null) {
      pushMatrix();
      resetMatrix();
      fill(0, 180);
      rect(mouseX + 10, mouseY - 35, textWidth(hoveredAirport.name) + 10, 25);
      fill(255);
      textSize(14);
      text(hoveredAirport.name, mouseX + 15, mouseY - 18);
      popMatrix();
    }
  }

  // Get Airport Positions
  private PVector getAirportPosition(String airportCode) {
    for (Airport airport : airports) {
      if (airport.code.equals(airportCode)) {
        return new PVector(airport.x, airport.y);
      }
    }
    return new PVector(-1, -1); // Not found
  }

  // Show airport flight summary in box
  private void showAirportFlightSummary(Airport airport, float x, float y) {
    int incoming = 0;
    int outgoing = 0;
    int delayed = 0;
    int cancelled = 0;
    x = 820;
    y = 160;

    // Count flights for this airport
    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      TableRow row = super.tableToDisplay.getRow(i);
      String origin = row.getString("ORIGIN");
      String destination = row.getString("DEST");

      if (origin.equals(airport.code)) {
        outgoing++;

        // Check delay status
        String lateValue = row.getString("LATE");
        if (lateValue != null) {
          if (lateValue.startsWith("+")) {
            delayed++;
          } else if (lateValue.equals("[cancelled]")) {
            cancelled++;
          }
        }
      }

      if (destination.equals(airport.code)) {
        incoming++;
      }
    }

    // Draw panel
    fill(40, 40, 80, 240);
    rect(x, 320, y, 140, 5);

    fill(255);
    textSize(14);
    textAlign(LEFT, TOP);

    text("Airport: " + airport.name, x + 10, y + 170);
    text("Code: " + airport.code, x + 10, y + 190);
    text("Outgoing flights: " + outgoing, x + 10, y + 210);
    text("Incoming flights: " + incoming, x + 10, y + 230);
    text("Delayed flights: " + delayed, x + 10, y + 250);
    text("Cancelled flights: " + cancelled, x + 10, y + 270);

    textAlign(CENTER, CENTER);
  }

  private void drawStateInfoPanel(float x, float y) {
    if (selectedState == null) return;

    String stateName = selectedState; // Default to abbr if name lookup fails
    for (State state : states) {
      if (state.abbr.equals(selectedState)) {
        stateName = state.name;
        break;
      }
    }

    // Get stats
    int departures = 0, arrivals = 0, delays = 0, cancels = 0;
    HashMap<String, Integer> originCounts = new HashMap<String, Integer>();
    HashMap<String, Integer> destinationCounts = new HashMap<String, Integer>();

    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      TableRow row = super.tableToDisplay.getRow(i);
      String originState = row.getString("ORIGIN_STATE_ABR");
      String destState = row.getString("DEST_STATE_ABR");

      if (originState.equals(selectedState)) {
        departures++;
        String origin = row.getString("ORIGIN");
        if (!originCounts.containsKey(origin)) {
          originCounts.put(origin, 1);
        } else {
          originCounts.put(origin, originCounts.get(origin) + 1);
        }

        // Check for delays and cancellations
        String lateValue = row.getString("LATE");
        if (lateValue != null) {
          if (lateValue.startsWith("+")) {
            delays++;
          } else if (lateValue.equals("[cancelled]")) {
            cancels++;
          }
        }
      }

      if (destState.equals(selectedState)) {
        arrivals++;
        String dest = row.getString("DEST");
        if (!destinationCounts.containsKey(dest)) {
          destinationCounts.put(dest, 1);
        } else {
          destinationCounts.put(dest, destinationCounts.get(dest) + 1);
        }
      }
    }

    String topOrigin = getTopAirport(originCounts);
    String topDest = getTopAirport(destinationCounts);

    // Draw info box
    fill(0, 200);
    rect(x, y, 230, 160, 5);
    fill(255);
    textSize(14);
    textAlign(LEFT, TOP);

    text("State: " + stateName, x + 10, y + 10);
    text("Departures: " + departures, x + 10, y + 30);
    text("Arrivals: " + arrivals, x + 10, y + 50);
    text("Top Origin: " + topOrigin, x + 10, y + 70);
    text("Top Dest: " + topDest, x + 10, y + 90);
    text("Delays: " + delays, x + 10, y + 110);
    text("Cancellations: " + cancels, x + 10, y + 130);

    textAlign(CENTER, CENTER);
  }

  private String getTopAirport(HashMap<String, Integer> map) {
    String top = "";
    int max = 0;
    for (String code : map.keySet()) {
      if (map.get(code) > max) {
        max = map.get(code);
        top = code;
      }
    }
    return top.equals("") ? "N/A" : top;
  }

  private void drawInfoPanel(float x, float y, float w, float h) {
    fill(40, 40, 80, 200);
    rect(x + 10, y + h - 80, 200, 70, 5);

    fill(255);
    textSize(12);
    textAlign(LEFT, TOP);

    text("Mouse wheel to zoom", x + 20, y + h - 55);
    text("Click airport for details", x + 20, y + h - 40);

    // Show active filters
    if (!selectedAirline.isEmpty()) {
      fill(40, 40, 80, 200);
      rect(x + w - 210, y + h - 80, 200, 70, 5);

      fill(255);
      text("Active Filters:", x + w - 200, y + h - 70);

      if (!selectedAirline.isEmpty()) {
        text("Airline: " + selectedAirline, x + w - 200, y + h - 55);
      }
    }

    textAlign(CENTER, CENTER);
  }

  // Mouse functions
  // updated so the bounding box strategy works for zooming, clicking, dragging -Chloe
  public void doMousePressed(float mx, float my) {
    int leftMargin = 50;
    int topMargin = 180;
    int mapWidth = width - 250;
    int mapHeight = 490;

    // Check if mouse is within the map frame
    if (mx > leftMargin && mx < leftMargin + mapWidth &&
      my > topMargin && my < topMargin + mapHeight) {
      dragging = true;
      lastMouseX = mx;
      lastMouseY = my;

      // Convert screen coordinates to map coordinates
      float mapCenterX = leftMargin + mapWidth/2;
      float mapCenterY = topMargin + mapHeight/2;
      float adjustedMouseX = (mx - mapCenterX - offsetX) / zoom;
      float adjustedMouseY = (my - mapCenterY - offsetY) / zoom;

      // Check for airport selection
      selectedAirport = null;
      selectedState = null;
      for (Airport airport : airports) {
        if (dist(adjustedMouseX, adjustedMouseY, airport.x, airport.y) < 8) {
          selectedAirport = airport;
          break;
        }
      }

      // No airport clicked? Check selected state
      if (selectedAirport == null) {
        for (State state : states) {
          if (dist(adjustedMouseX, adjustedMouseY, state.x, state.y) < 15) {
            selectedState = state.abbr;
            break;
          }
        }
      }
    }
  }

  public void doMouseDragged(float mx, float my) {
    if (!dragging) return;

    // Calculate new offsets
    float dx = mx - lastMouseX;
    float dy = my - lastMouseY;

    // Update pan offsets
    offsetX += dx;
    offsetY += dy;

    // Constrain to boundaries
    int mapWidth = width - 250;
    int mapHeight = 490;

    // Only constrain if zoomed in
    if (zoom > 1.0) {
      // Calculate the maximum panning limits based on current zoom
      float maxOffsetX = (mapWidth * zoom - mapWidth) / 2;
      float maxOffsetY = (mapHeight * zoom - mapHeight) / 2;

      // Constrain the offsets to keep the content within the map frame
      offsetX = constrain(offsetX, -maxOffsetX, maxOffsetX);
      offsetY = constrain(offsetY, -maxOffsetY, maxOffsetY);
    } else {
      // no zoom: center the map
      offsetX = 0;
      offsetY = 0;
    }

    lastMouseX = mx;
    lastMouseY = my;
  }

  public void doMouseReleased() {
    dragging = false;
  }

  void doMouseWheel(float count) {
    int leftMargin = 50;
    int topMargin = 180;
    int mapWidth = width - 250;
    int mapHeight = 490;

    // Only zoom if mouse is over the map
    if (mouseX > leftMargin && mouseX < leftMargin + mapWidth &&
      mouseY > topMargin && mouseY < topMargin + mapHeight) {

      // Update zoom level
      float zoomFactor = 0.05;
      zoomTarget += count * -zoomFactor;  // Negative because wheel down should zoom out
      zoomTarget = constrain(zoomTarget, 0.8, 2.5);  // Limit zoom range
      zoom += (zoomTarget - zoom) * 0.1;  // Smooth zoom animation

      // If zooming out to normal or less, reset offsets
      if (zoom <= 1.0) {
        offsetX = 0;
        offsetY = 0;
      } else {
        // Calculate the maximum panning limits based on current zoom
        float maxOffsetX = (mapWidth * zoom - mapWidth) / 2;
        float maxOffsetY = (mapHeight * zoom - mapHeight) / 2;

        // Constrain the offsets to keep the content within the map frame
        offsetX = constrain(offsetX, -maxOffsetX, maxOffsetX);
        offsetY = constrain(offsetY, -maxOffsetY, maxOffsetY);
      }
    }
  }

  private int calculateVisibleFlightCount() {
    int count = 0;

    for (int i = 0; i < super.tableToDisplay.getRowCount(); i++) {
      TableRow row = super.tableToDisplay.getRow(i);

      // Apply filters
      if (!selectedAirline.isEmpty() && !row.getString("MKT_CARRIER").equals(selectedAirline)) {
        continue;
      }

      String origin = row.getString("ORIGIN");
      String destination = row.getString("DEST");
      PVector originPos = getAirportPosition(origin);
      PVector destPos = getAirportPosition(destination);

      // Count if both airports are found
      if (originPos.x != -1 && destPos.x != -1) {
        count++;
      }
    }
    return count;
  }

  public void resetFilters() {
    selectedAirline = "";
    selectedAirport = null;
    selectedState = null;
  }
  //methods below changed and extended to work with Web Mercator Projection -Chloe

  /**
   * Converts longitude to X coordinate using Web Mercator projection
   * get lon Longitude in degrees, returns x coordinate for the given longitude
   */
  private float mercatorLongitudeToX(float lon) {
    // Map the longitude to a value between 0-1 based on the map boundaries
    float normalizedLon = (lon - MAP_WEST) / (MAP_EAST - MAP_WEST);

    // Map to screen coordinates, centered on the map
    float mapWidth = (width - 250) * 0.9;  // Match image width in draw()
    return map(normalizedLon, 0, 1, -mapWidth/2, mapWidth/2);
  }

  /**
   * Converts latitude to Y coordinate using Web Mercator projection
   * get lat Latitude in degrees, returns y coordinate for the given latitude
   */
  private float mercatorLatitudeToY(float lat) {
    // Constrain latitude to avoid infinity
    lat = constrain(lat, -85, 85);

    // Convert latitude to radians
    float latRad = radians(lat);

    // Apply Mercator projection formula
    float mercatorY = log(tan(PI/4 + latRad/2));

    // Get the mercator y values for the map boundaries
    float northMercator = log(tan(PI/4 + radians(MAP_NORTH)/2));
    float southMercator = log(tan(PI/4 + radians(MAP_SOUTH)/2));

    // mercator value (0 = north edge, 1 = south edge)
    float normalizedY = (mercatorY - northMercator) / (southMercator - northMercator);

    // Map to screen coordinates, inverted (y increases going down)
    float mapHeight = 490 * 0.9;
    return map(normalizedY, 0, 1, -mapHeight/2, mapHeight/2);
  }

  // Updated loadStates method with comprehensive state positions
  //
  private void loadStates() {
    // These are actual geographic centers of states (latitude, longitude)
    // source: https://en.wikipedia.org/wiki/List_of_geographic_centers_of_the_United_States
    //Chloe
    states.add(new State("AL", "Alabama", 32.7990, -86.8073));
    states.add(new State("AK", "Alaska", 61.3850, -152.2683));
    states.add(new State("AZ", "Arizona", 34.2744, -111.6602));
    states.add(new State("AR", "Arkansas", 34.9513, -92.3809));
    states.add(new State("CA", "California", 37.1841, -119.4696));
    states.add(new State("CO", "Colorado", 38.9972, -105.5478));
    states.add(new State("CT", "Connecticut", 41.6219, -72.7273));
    states.add(new State("DE", "Delaware", 38.9896, -75.5050));
    states.add(new State("FL", "Florida", 28.1740, -81.4900));
    states.add(new State("GA", "Georgia", 32.6415, -83.4426));
    states.add(new State("HI", "Hawaii", 20.2927, -156.3737));
    states.add(new State("ID", "Idaho", 44.3509, -114.6130));
    states.add(new State("IL", "Illinois", 40.0417, -89.1965));
    states.add(new State("IN", "Indiana", 39.8942, -86.2816));
    states.add(new State("IA", "Iowa", 42.0751, -93.4960));
    states.add(new State("KS", "Kansas", 38.4937, -98.3804));
    states.add(new State("KY", "Kentucky", 37.5347, -85.3021));
    states.add(new State("LA", "Louisiana", 31.0689, -91.9968));
    states.add(new State("ME", "Maine", 45.3695, -69.2428));
    states.add(new State("MD", "Maryland", 39.0550, -76.7909));
    states.add(new State("MA", "Massachusetts", 42.2596, -71.8083));
    states.add(new State("MI", "Michigan", 43.7, -85));
    states.add(new State("MN", "Minnesota", 46.2807, -94.3053));
    states.add(new State("MS", "Mississippi", 32.7364, -89.6678));
    states.add(new State("MO", "Missouri", 38.4623, -92.3020));
    states.add(new State("MT", "Montana", 46.9219, -110.4544));
    states.add(new State("NE", "Nebraska", 41.5378, -99.7951));
    states.add(new State("NV", "Nevada", 39.3289, -116.6312));
    states.add(new State("NH", "New Hampshire", 43.6805, -71.5811));
    states.add(new State("NJ", "New Jersey", 40.1907, -74.6728));
    states.add(new State("NM", "New Mexico", 34.4071, -106.1126));
    states.add(new State("NY", "New York", 42.9538, -75.5268));
    states.add(new State("NC", "North Carolina", 35.5557, -79.3877));
    states.add(new State("ND", "North Dakota", 47.4501, -100.4659));
    states.add(new State("OH", "Ohio", 40.2862, -82.7937));
    states.add(new State("OK", "Oklahoma", 35.5889, -97.4943));
    states.add(new State("OR", "Oregon", 43.9336, -120.5583));
    states.add(new State("PA", "Pennsylvania", 40.8781, -77.7996));
    states.add(new State("RI", "Rhode Island", 41.6762, -71.5562));
    states.add(new State("SC", "South Carolina", 33.9169, -80.8964));
    states.add(new State("SD", "South Dakota", 44.4443, -100.2263));
    states.add(new State("TN", "Tennessee", 35.8580, -86.3505));
    states.add(new State("TX", "Texas", 31.4757, -99.3312));
    states.add(new State("UT", "Utah", 39.3055, -111.6703));
    states.add(new State("VT", "Vermont", 44.0687, -72.6658));
    states.add(new State("VA", "Virginia", 37.5215, -78.8537));
    states.add(new State("WA", "Washington", 47.3826, -120.4472));
    states.add(new State("WV", "West Virginia", 38.6409, -80.6227));
    states.add(new State("WI", "Wisconsin", 44.6243, -89.9941));
    states.add(new State("WY", "Wyoming", 42.9957, -107.5512));
  }

  private void calculateStatePositions() {
    for (State state : states) {
      // Convert geographic coordinates to internal map coordinates using Mercator projection
      state.x = mercatorLongitudeToX(state.lon);
      state.y = mercatorLatitudeToY(state.lat);
    }
  }

  /* These are actual (approx.) coordinates of airport (latitude, longitude).
   * Some have been lightly edited from original data for visual consistency with map image.
   * source: https://www.latlong.net/category/airports-236-19.html
   * Chloe 9/4/25
   */
  private float getLatFromCode(String code) {
    switch (code) {
    case "ABQ":
      return 35.0402;    // Albuquerque
    case "ALB":
      return 42.7482;    // Albany
    case "ATL":
      return 33.6407;    // Atlanta
    case "ATW":
      return 44.2581;    // Appleton
    case "AUS":
      return 30.1945;    // Austin
    case "AZA":
      return 33.3078;    // Phoenix-Mesa
    case "BDL":
      return 41.9389;    // Hartford
    case "BHM":
      return 33.5629;    // Birmingham
    case "BIL":
      return 45.8077;    // Billings
    case "BIS":
      return 46.7730;    // Bismarck
    case "BLI":
      return 48.7927;    // Bellingham
    case "BLV":
      return 38.5454;    // Belleville
    case "BNA":
      return 36.1263;    // Nashville
    case "BOI":
      return 43.5644;    // Boise
    case "BOS":
      return 42.3656;    // Boston
    case "BUF":
      return 42.9405;    // Buffalo
    case "BUR":
      return 34.2007;    // Burbank
    case "BWI":
      return 39.1774;    // Baltimore
    case "BZN":
      return 45.7772;    // Bozeman
    case "CHS":
      return 32.8938;    // Charleston
    case "CID":
      return 41.8847;    // Cedar Rapids
    case "CLE":
      return 41.4095;    // Cleveland
    case "CLT":
      return 35.2144;    // Charlotte
    case "CMH":
      return 39.9980;    // Columbus
    case "COS":
      return 38.8058;    // Colorado Springs
    case "CRP":
      return 27.7700;    // Corpus Christi
    case "CVG":
      return 39.0488;    // Cincinnati
    case "DAL":
      return 32.8481;    // Dallas Love
    case "DCA":
      return 38.8512;    // Washington National
    case "DEN":
      return 39.8561;    // Denver
    case "DFW":
      return 32.8998;    // Dallas-Fort Worth
    case "DTW":
      return 42.2124;    // Detroit
    case "ELP":
      return 31.8072;    // El Paso
    case "EUG":
      return 44.1246;    // Eugene
    case "EWR":
      return 40.6925;    // Newark
    case "FAR":
      return 46.9207;    // Fargo
    case "FAT":
      return 36.7758;    // Fresno
    case "FLL":
      return 26.0742;    // Fort Lauderdale
    case "GEG":
      return 47.6199;    // Spokane
    case "GJT":
      return 39.1225;    // Grand Junction
    case "GSP":
      return 34.8957;    // Greenville
    case "GTF":
      return 47.4824;    // Great Falls
    case "HDN":
      return 40.4812;    // Hayden
    case "HOU":
      return 29.6454;    // Houston Hobby
    case "HPN":
      return 41.0670;    // White Plains
    case "IAH":
      return 29.9844;    // Houston Bush
    case "IDA":
      return 43.5136;    // Idaho Falls
    case "IND":
      return 39.7169;    // Indianapolis
    case "JAN":
      return 32.3113;    // Jackson
    case "JAX":
      return 30.4941;    // Jacksonville
    case "JFK":
      return 40.6413;    // New York JFK
    case "LAS":
      return 36.0840;    // Las Vegas
    case "LAX":
      return 33.9416;    // Los Angeles
    case "LBB":
      return 33.6636;    // Lubbock
    case "LGA":
      return 40.7769;    // New York LaGuardia
    case "LGB":
      return 33.8177;    // Long Beach
    case "MAF":
      return 31.9425;    // Midland
    case "MCI":
      return 39.2976;    // Kansas City
    case "MCO":
      return 28.4312;    // Orlando
    case "MDW":
      return 41.7860;    // Chicago Midway
    case "MEM":
      return 35.0420;    // Memphis
    case "MFE":
      return 25.65;    // McAllen
    case "MFR":
      return 42.3742;    // Medford
    case "MIA":
      return 25.7932;    // Miami
    case "MKE":
      return 42.9472;    // Milwaukee
    case "MOT":
      return 48.2575;    // Minot
    case "MSO":
      return 46.9163;    // Missoula
    case "MSP":
      return 44.8848;    // Minneapolis
    case "MSY":
      return 29.9934;    // New Orleans
    case "MYR":
      return 33.6797;    // Myrtle Beach
    case "OAK":
      return 37.7214;    // Oakland
    case "OKC":
      return 35.3931;    // Oklahoma City
    case "ORD":
      return 41.9742;    // Chicago O'Hare
    case "ORF":
      return 36.8946;    // Norfolk
    case "PBI":
      return 26.4;    // West Palm Beach
    case "PDX":
      return 45.5887;    // Portland
    case "PHL":
      return 39.8729;    // Philadelphia
    case "PHX":
      return 33.4342;    // Phoenix
    case "PIA":
      return 40.6642;    // Peoria
    case "PIT":
      return 40.4915;    // Pittsburgh
    case "PSP":
      return 33.8221;    // Palm Springs
    case "PVD":
      return 41.7240;    // Providence
    case "RAP":
      return 44.0453;    // Rapid City
    case "RDU":
      return 35.8776;    // Raleigh-Durham
    case "RFD":
      return 42.1953;    // Rockford
    case "RIC":
      return 37.5052;    // Richmond
    case "RNO":
      return 39.4991;    // Reno
    case "ROC":
      return 43.1186;    // Rochester
    case "RSW":
      return 26.5362;    // Fort Myers
    case "SAN":
      return 32.7335;    // San Diego
    case "SAT":
      return 29.5337;    // San Antonio
    case "SAV":
      return 32.1275;    // Savannah
    case "SBN":
      return 41.7087;    // South Bend
    case "SCK":
      return 37.8942;    // Stockton
    case "SDF":
      return 38.1740;    // Louisville
    case "SEA":
      return 47.4502;    // Seattle
    case "SFO":
      return 37.6188;    // San Francisco
    case "SGF":
      return 37.2456;    // Springfield
    case "SHV":
      return 32.4466;    // Shreveport
    case "SJC":
      return 37.3639;    // San Jose
    case "SLC":
      return 40.7883;    // Salt Lake City
    case "SMF":
      return 38.6953;    // Sacramento
    case "SMX":
      return 34.8989;    // Santa Maria
    case "SNA":
      return 33.6762;    // Santa Ana
    case "SRQ":
      return 27.3934;    // Sarasota
    case "STL":
      return 38.7487;    // St. Louis
    case "TPA":
      return 27.9756;    // Tampa
    case "TUL":
      return 36.1984;    // Tulsa
    case "VPS":
      return 30.4830;    // Valparaiso
    case "XNA":
      return 36.2818;    // Fayetteville
    default:
      return 0;
    }
  }


  private float getLonFromCode(String code) {
    switch (code) {
    case "ABQ":
      return -106.6090;  // Albuquerque
    case "ALB":
      return -73.8021;   // Albany
    case "ATL":
      return -84.4277;   // Atlanta
    case "ATW":
      return -88.5190;   // Appleton
    case "AUS":
      return -97.6699;   // Austin
    case "AZA":
      return -111.6552;  // Phoenix-Mesa
    case "BDL":
      return -72.6882;   // Hartford
    case "BHM":
      return -86.7528;   // Birmingham
    case "BIL":
      return -108.5428;  // Billings
    case "BIS":
      return -100.7580;  // Bismarck
    case "BLI":
      return -122.5376;  // Bellingham
    case "BLV":
      return -89.8362;   // Belleville
    case "BNA":
      return -86.6799;   // Nashville
    case "BOI":
      return -116.2223;  // Boise
    case "BOS":
      return -71.0096;   // Boston
    case "BUF":
      return -78.7320;   // Buffalo
    case "BUR":
      return -118.3585;  // Burbank
    case "BWI":
      return -76.6684;   // Baltimore
    case "BZN":
      return -111.1603;  // Bozeman
    case "CHS":
      return -80.0405;   // Charleston
    case "CID":
      return -91.7109;   // Cedar Rapids
    case "CLE":
      return -81.8548;   // Cleveland
    case "CLT":
      return -80.9472;   // Charlotte
    case "CMH":
      return -82.8849;   // Columbus
    case "COS":
      return -104.7003;  // Colorado Springs
    case "CRP":
      return -97.5012;   // Corpus Christi
    case "CVG":
      return -84.6673;   // Cincinnati
    case "DAL":
      return -96.8512;   // Dallas Love
    case "DCA":
      return -77.0377;   // Washington National
    case "DEN":
      return -104.6737;  // Denver
    case "DFW":
      return -97.0403;   // Dallas-Fort Worth
    case "DTW":
      return -83.3534;   // Detroit
    case "ELP":
      return -106.3778;  // El Paso
    case "EUG":
      return -123.2178;  // Eugene
    case "EWR":
      return -74.1687;   // Newark
    case "FAR":
      return -96.8158;   // Fargo
    case "FAT":
      return -119.7181;  // Fresno
    case "FLL":
      return -80.2;   // Fort Lauderdale
    case "GEG":
      return -117.5342;  // Spokane
    case "GJT":
      return -108.5267;  // Grand Junction
    case "GSP":
      return -82.2186;   // Greenville
    case "GTF":
      return -111.3701;  // Great Falls
    case "HDN":
      return -107.2177;  // Hayden
    case "HOU":
      return -95.2789;   // Houston Hobby
    case "HPN":
      return -73.7076;   // White Plains
    case "IAH":
      return -95.3414;   // Houston Bush
    case "IDA":
      return -112.0708;  // Idaho Falls
    case "IND":
      return -86.2956;   // Indianapolis
    case "JAN":
      return -90.0755;   // Jackson
    case "JAX":
      return -81.6879;   // Jacksonville
    case "JFK":
      return -73.7781;   // New York JFK
    case "LAS":
      return -115.1537;  // Las Vegas
    case "LAX":
      return -118.4085;  // Los Angeles
    case "LBB":
      return -101.8229;  // Lubbock
    case "LGA":
      return -73.8740;   // New York LaGuardia
    case "LGB":
      return -118.1525;  // Long Beach
    case "MAF":
      return -102.2019;  // Midland
    case "MCI":
      return -94.7138;   // Kansas City
    case "MCO":
      return -81.3080;   // Orlando
    case "MDW":
      return -87.7524;   // Chicago Midway
    case "MEM":
      return -89.9767;   // Memphis
    case "MFE":
      return -98.2361;   // McAllen
    case "MFR":
      return -122.8735;  // Medford
    case "MIA":
      return -80.2906;   // Miami
    case "MKE":
      return -87.8964;   // Milwaukee
    case "MOT":
      return -101.2797;  // Minot
    case "MSO":
      return -114.0896;  // Missoula
    case "MSP":
      return -93.2166;   // Minneapolis
    case "MSY":
      return -90.2580;   // New Orleans
    case "MYR":
      return -78.9288;   // Myrtle Beach
    case "OAK":
      return -122.2208;  // Oakland
    case "OKC":
      return -97.6007;   // Oklahoma City
    case "ORD":
      return -87.9073;   // Chicago O'Hare
    case "ORF":
      return -76.2010;   // Norfolk
    case "PBI":
      return -80.3;   // West Palm Beach
    case "PDX":
      return -122.5969;  // Portland
    case "PHL":
      return -75.2420;   // Philadelphia
    case "PHX":
      return -112.0118;  // Phoenix
    case "PIA":
      return -89.6906;   // Peoria
    case "PIT":
      return -80.2329;   // Pittsburgh
    case "PSP":
      return -116.5069;  // Palm Springs
    case "PVD":
      return -71.4266;   // Providence
    case "RAP":
      return -103.0576;  // Rapid City
    case "RDU":
      return -78.7879;   // Raleigh-Durham
    case "RFD":
      return -89.0972;   // Rockford
    case "RIC":
      return -77.3197;   // Richmond
    case "RNO":
      return -119.7681;  // Reno
    case "ROC":
      return -77.6724;   // Rochester
    case "RSW":
      return -81.7552;   // Fort Myers
    case "SAN":
      return -117.1904;  // San Diego
    case "SAT":
      return -98.4698;   // San Antonio
    case "SAV":
      return -81.2021;   // Savannah
    case "SBN":
      return -86.3178;   // South Bend
    case "SCK":
      return -121.2388;  // Stockton
    case "SDF":
      return -85.7364;   // Louisville
    case "SEA":
      return -122.3088;  // Seattle
    case "SFO":
      return -122.3922;  // San Francisco
    case "SGF":
      return -93.3891;   // Springfield
    case "SHV":
      return -93.8263;   // Shreveport
    case "SJC":
      return -121.9289;  // San Jose
    case "SLC":
      return -111.9778;  // Salt Lake City
    case "SMF":
      return -121.5901;  // Sacramento
    case "SMX":
      return -120.4575;  // Santa Maria
    case "SNA":
      return -117.8674;  // Santa Ana
    case "SRQ":
      return -82.5541;   // Sarasota
    case "STL":
      return -90.3700;   // St. Louis
    case "TPA":
      return -82.5330;   // Tampa
    case "TUL":
      return -95.8887;   // Tulsa
    case "VPS":
      return -86.5254;   // Valparaiso
    case "XNA":
      return -94.3068;   // Fayetteville
    default:
      return 0;
    }
  }
}

// Class for storing airports
class Airport {
  String name, code;
  float latitude, longitude;
  float x, y;

  Airport(String name, String code, float latitude, float longitude, float x, float y) {
    this.name = name;
    this.code = code;
    this.latitude = latitude;
    this.longitude = longitude;
    this.x = x;
    this.y = y;
  }
}

// Class for storing states
class State {
  String abbr, name;
  float lat, lon;
  float x, y;

  State(String abbr, String name, float lat, float lon) {
    this.abbr = abbr;
    this.name = name;
    this.lat = lat;
    this.lon = lon;
  }
}
