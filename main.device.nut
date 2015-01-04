// IO Expander Class for SX1509
class IoExpander
{
    i2cPort = null;
    i2cAddress = null;
 
    constructor(port, address)
    {
        if(port == I2C_12)
        {
            // Configure I2C bus on pins 1 & 2
            hardware.configure(I2C_12);
            i2cPort = hardware.i2c12;
        }
        else if(port == I2C_89)
        {
            // Configure I2C bus on pins 8 & 9
            hardware.configure(I2C_89);
            i2cPort = hardware.i2c89;
        }
        else
        {
            server.log("Invalid I2C port specified.");
        }
 
        i2cAddress = address << 1;
    }
 
    // Read a byte
    function read(register)
    {
        local data = i2cPort.read(i2cAddress, format("%c", register), 1);
        if(data == null)
        {
            server.log("I2C Read Failure");
            return -1;
        }
 
        return data[0];
    }
 
    // Write a byte
    function write(register, data)
    {
        i2cPort.write(i2cAddress, format("%c%c", register, data));
    }
 
    // Write a bit to a register
    function writeBit(register, bitn, level)
    {
        local value = read(register);
        value = (level == 0)?(value & ~(1<<bitn)):(value | (1<<bitn));
        write(register, value);
    }
 
    // Write a masked bit pattern
    function writeMasked(register, data, mask)
    {
       local value = read(register);
       value = (value & ~mask) | (data & mask);
       write(register, value);
    }
 
    // Set a GPIO level
    function setPin(gpio, level)
    {
        writeBit(gpio>=8?0x10:0x11, gpio&7, level?1:0);
    }
 
    // Set a GPIO direction
    function setDir(gpio, output)
    {
        writeBit(gpio>=8?0x0e:0x0f, gpio&7, output?0:1);
    }
 
    // Set a GPIO internal pull up
    function setPullUp(gpio, enable)
    {
        writeBit(gpio>=8?0x06:0x07, gpio&7, enable);
    }
 
    // Set GPIO interrupt mask
    function setIrqMask(gpio, enable)
    {
        writeBit(gpio>=8?0x12:0x13, gpio&7, enable);
    }
 
    // Set GPIO interrupt edges
    function setIrqEdges(gpio, rising, falling)
    {
        local addr = 0x17 - (gpio>>2);
        local mask = 0x03 << ((gpio&3)<<1);
        local data = (2*falling + rising) << ((gpio&3)<<1);    
        writeMasked(addr, data, mask);
    }
 
    // Clear an interrupt
    function clearIrq(gpio)
    {
        writeBit(gpio>=8?0x18:0x19, gpio&7, 1);
    }
 
    // Get a GPIO input pin level
    function getPin(gpio)
    {
        return (read(gpio>=8?0x10:0x11)&(1<<(gpio&7)))?1:0;
    }
}


// RGB LED Class
class RgbLed extends IoExpander
{
    // IO Pin assignments
    pinR = null;
    pinG = null;
    pinB = null;
 
    constructor(port, address, r, g, b)
    {
        base.constructor(port, address);
 
        // Save pin assignments
        pinR = r;
        pinG = g;
        pinB = b;
 
        // Disable pin input buffers
        writeBit(pinR>7?0x00:0x01, pinR>7?(pinR-7):pinR, 1);
        writeBit(pinG>7?0x00:0x01, pinG>7?(pinG-7):pinG, 1);
        writeBit(pinB>7?0x00:0x01, pinB>7?(pinB-7):pinB, 1);
 
        // Set pins as outputs
        writeBit(pinR>7?0x0E:0x0F, pinR>7?(pinR-7):pinR, 0);
        writeBit(pinG>7?0x0E:0x0F, pinG>7?(pinG-7):pinG, 0);
        writeBit(pinB>7?0x0E:0x0F, pinB>7?(pinB-7):pinB, 0);
 
        // Set pins open drain
        writeBit(pinR>7?0x0A:0x0B, pinR>7?(pinR-7):pinR, 1);
        writeBit(pinG>7?0x0A:0x0B, pinG>7?(pinG-7):pinG, 1);
        writeBit(pinB>7?0x0A:0x0B, pinB>7?(pinB-7):pinB, 1);
 
        // Enable LED drive
        writeBit(pinR>7?0x20:0x21, pinR>7?(pinR-7):pinR, 1);
        writeBit(pinG>7?0x20:0x21, pinG>7?(pinG-7):pinG, 1);
        writeBit(pinB>7?0x20:0x21, pinB>7?(pinB-7):pinB, 1);
 
        // Set to use internal 2MHz clock, linear fading
        write(0x1e, 0x50);
        write(0x1f, 0x10);
 
        // Initialise as inactive
        setLevels(0, 0, 0);
        setPin(pinR, 0);
        setPin(pinG, 0);
        setPin(pinB, 0);
    }
 
    // Set LED enabled state
    function setLed(r, g, b)
    {
        if(r != null) writeBit(pinR>7?0x20:0x21, pinR&7, r);
        if(g != null) writeBit(pinG>7?0x20:0x21, pinG&7, g);
        if(b != null) writeBit(pinB>7?0x20:0x21, pinB&7, b);
    }
 
    // Set red, green and blue intensity levels
    function setLevels(r, g, b)
    {
        if(r != null) write(pinR<4?0x2A+pinR*3:0x36+(pinR-4)*5, r);
        if(g != null) write(pinG<4?0x2A+pinG*3:0x36+(pinG-4)*5, g);
        if(b != null) write(pinB<4?0x2A+pinB*3:0x36+(pinB-4)*5, b);
    }
}
 

 
// Temperature Sensor Class for SA56004X
class TemperatureSensor
{
    i2cPort = null;
    i2cAddress = null;
    conversionRate = 0x04;
 
    constructor(port, address)
    {
        if(port == I2C_12)
        {
            // Configure I2C bus on pins 1 & 2
            hardware.configure(I2C_12);
            i2cPort = hardware.i2c12;
        }
        else if(port == I2C_89)
        {
            // Configure I2C bus on pins 8 & 9
            hardware.configure(I2C_89);
            i2cPort = hardware.i2c89;
        }
        else
        {
            server.log("Invalid I2C port specified.");
        }
 
        i2cAddress = address << 1;
 
        // Configure device for single shot, no alarms
        write(0x09, 0xD5);
 
        // Set default conversion rate (1Hz)
        setRate(conversionRate);
    }
 
    // Read a byte
    function read(register)
    {
        local data = i2cPort.read(i2cAddress, format("%c", register), 1);
        if(data == null)
        {
            server.log("I2C Read Failure");
            return -1;
        }
 
        return data[0];
    }
 
    // Write a byte
    function write(register, data)
    {
        i2cPort.write(i2cAddress, format("%c%c", register, data));
    }
 
    // Set continuous conversion rate, 0 = 0.06Hz, 4 = 1Hz, 9 = 32Hz
    function setRate(rate)
    {
        if(rate >= 0 && rate <= 9)
        {
            write(0x0a, rate);
            conversionRate = rate;
        }
        else
        {
            write(0x0a, 0x04);
            conversionRate = 0x04;
            server.log("Invalid conversion rate, using default 1Hz");
        }
 
    }
 
    // Stop continuous conversion
    function stop()
    {
        write(0x09, 0xD5);
    }
 
    // Start conversion, continuous or single shot
    function start(continuous)
    {
        if(continuous == true)
        {
            write(0x09, 0x55);
        }
        else
        {
            write(0x0f, 0x00);
        }
    }
 
    // Check if conversion is completed
    function isReady()
    {        
        return (read(0x02) & 0x80)?false:true;
    }
 
    // Retrieve temperature (from local sensor) in deg F
    function getTemperature()
    {
        // Get 11-bit signed temperature value in 0.125C steps
        local temp = (read(0x00) << 3) | (read(0x22) >> 5);
 
        if(temp & 0x400)
        {
            // Negative two's complement value
            return -((~temp & 0x7FF) + 1) / 8.0;
        }
        else
        {
            // Positive value
            local temp_c = temp / 8.0;
            local temp_f = temp_c * 1.8 + 32;
            return temp_f;
        }
    }
}
 
// Instantiate the sensor
local sensor = TemperatureSensor(I2C_89, 0x4c);
 
// Output port to send temperature readings
local output = OutputPort("Temperature", "number");
 

 
// Capture and log a temperature reading every 5s
function capture()
{
    // Set timer for the next capture
    imp.wakeup(300.0, capture);
 
    // Start a single shot conversion
    sensor.start(false);
 
    // Wait for conversion to complete
    while(!sensor.isReady()) imp.sleep(0.05);
 
    // Output the temperature
    local temp = sensor.getTemperature();
    //output.set(temp);
    server.log(format("Temp, %3.1f", temp));
    //agent.send(format("Temp, %3.1f", temp));
    agent.send("temperature",format("Temp, %3.1f", temp));
}
 
// Register with the server
imp.configure("Temperature Logger v1.1", [], []);

// Construct an LED
local led = RgbLed(I2C_89, 0x3E, 7, 5, 6);
 
// Set the LED color
led.setLed(1, 1, 1);
led.setLevels(6, 0, 0); 

///////Test Stuff

///////End Test Stuff


// Start capturing temperature
capture();
 
// End of code.
