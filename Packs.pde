int SIZE = 16,
    SIGHT = 50,
    COMFORT_ZONE = 30;
float SPEED = 2.0/10.0,
      FRICTION = 0.97,
      COOPERATION = 0.35;

ArrayList<Okami> allOkami;
ArrayList<Pack> packs;
color[] palette = {#490a3d, #bd1550, #e97f02, #f8ca00, #8a9b0f, #00a0b0};

void setup() {
  size(800, 800);

  allOkami = new ArrayList();
  packs = new ArrayList();
  
  for(int i = 0; i < 4; i++) {
    packs.add(new Pack(random(width), random(height), palette[i], 100));
  }
}

void draw() {
  background(128);

  for(Pack pack : packs) {
    pack.act();
    pack.display();
  }
  
  fill(0);
  text(frameRate + " fps", 0, 10);
}

class Target {
  private PVector coordinates;
  private float x;
  private float y;
  private float rotation;
  private color targetColor;

  Target(float x, float y, color targetColor) {
    coordinates = new PVector(x, y);
    this.targetColor = targetColor;
    rotation = 0;
  }
  
  public void display() {
    pushMatrix();
    pushStyle();
    noFill();
    stroke(targetColor);
    translate(coordinates.x, coordinates.y);
    rotate(rotation);
    arc(0, 0, 20, 20, 0, HALF_PI);
    arc(0, 0, 20, 20, PI, PI+HALF_PI);
    popStyle();
    popMatrix();
    rotation = (rotation + 0.01) % PI; 
  }
  
  public void move() {
    coordinates = new PVector(random(width), random(height)); 
  }
}

class Pack {
  private ArrayList<Okami> okami;
  private Target target;
  
  Pack(float x, float y, color packColor, int size) {
    okami = new ArrayList();
    float boxWidth = sqrt(size);

    for (int i = 0; i < size; i++) {
      Okami o = new Okami(x + (i % boxWidth), y + (i / boxWidth), SIGHT,
                          COMFORT_ZONE, COOPERATION, SPEED, SIZE, packColor, this);
      okami.add(o);
      allOkami.add(o);
    }
    
    target = new Target(x, y, packColor); 
  }
  
  public void act() {
    for (Okami o : okami) {
      o.act(); 
    }
  }
  
  public void display() {
    for (Okami o : okami) {
      o.display();
    }
   
    target.display(); 
  }
}

class Okami {
  private PVector coordinates;
  private PVector velocity;
  private color okamiColor;
  private int sight;
  private int comfortZone;
  private float cooperation;
  private float speed;
  private int size;
  private Pack pack;

  Okami(float x, float y, int sight, int comfortZone, float cooperation,
        float speed, int size, color okamiColor, Pack pack) {
    this.coordinates = new PVector(x, y);
    this.sight = sight;
    this.comfortZone = comfortZone;
    this.cooperation = cooperation;
    this.speed = speed;
    this.size = size;
    this.okamiColor = okamiColor;
    this.pack = pack;
    this.velocity = new PVector(0, 0);
  }

  private ArrayList<Okami> okamiInSight() {
    ArrayList<Okami> inSight = new ArrayList();

    for (Okami o : allOkami) {
      if(coordinates.dist(o.coordinates) <= sight && !o.equals(this)) {
        inSight.add(o);
      }
    }
    
    return inSight;
  }
  
  private ArrayList<Okami> inPack(ArrayList<Okami> okami) {
    ArrayList<Okami> inPack = new ArrayList();

    for (Okami o : okami) {
      if (o.pack.equals(pack)) {
        inPack.add(o); 
      }
    }
    
    return inPack;
  }

  void act() {
    ArrayList<Okami> inSight = okamiInSight();
    ArrayList<Okami> inPack = inPack(inSight);

    velocity.add(cohesion(inPack));
    velocity.add(separation(inSight));
    velocity.add(alignment(inPack));
    velocity.add(seek(pack.target.coordinates));
    velocity.limit(3);
    coordinates.x += velocity.x;
    coordinates.y += velocity.y;
    checkBounds();    
    velocity.mult(FRICTION);
    
    if (PVector.sub(pack.target.coordinates, coordinates).mag() < comfortZone) {
      pack.target.move();
    }
  }
  
  void checkBounds() {
    if(coordinates.x > width || coordinates.x < 0) {
      coordinates.x -= velocity.x;
      velocity.x *= -1;
    }
    
    if(coordinates.y > height || coordinates.y < 0) {
      coordinates.y -= velocity.y;
      velocity.y *= -1;
    }
  }
  
  // Stay with the Pack.
  PVector cohesion(ArrayList<Okami> inPack) {
    if (inPack.size() == 0) { return new PVector(0, 0); }

    PVector center = new PVector(0, 0);

    for(Okami o : inPack) {
      center.add(PVector.div(o.coordinates, inPack.size()));
    }

    return seek(center);
  }
  
  // Don't crowd.
  PVector separation(ArrayList<Okami> inSight) {
    PVector repulsion = new PVector(0, 0);

    for(Okami o : inSight) {
      PVector difference = PVector.sub(o.coordinates, this.coordinates);

      if (difference.mag() < comfortZone) {
        difference.div(pow(difference.mag(), 2)/4);
        repulsion.sub(difference);
      }
    }

    return repulsion;
  }

  // Move with the Pack.
  PVector alignment(ArrayList<Okami> inPack) {
    PVector average = new PVector(0, 0);

    for(Okami o : inPack) {
      average.add(PVector.div(o.velocity, inPack.size()));
    }

    return PVector.mult(PVector.sub(average, velocity), cooperation);
  }

  PVector seek(PVector targetLocation) {
    PVector diff = PVector.sub(targetLocation, coordinates);
    diff.normalize();
    diff.mult(speed);
    return diff;
  }

  void display() {
    pushMatrix(); 
    translate(coordinates.x, coordinates.y);
    rotate(atan2(velocity.y, velocity.x));
    noStroke();
    fill(okamiColor);
    triangle(0, 0, -size, size/3, -size, -size/3);
    popMatrix();
  }  
}
