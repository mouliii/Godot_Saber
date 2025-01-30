using Godot;
using Godot.Collections;
using System;
using System.IO.Ports;

[GlobalClass]
public partial class USBComm : Node
{
	SerialPort serialPort;
	[Export] public int nBytesToRead = 10;
	[Export] public String commPort = "COM3";
	[Export] public int baudRate = 115200;
	private Byte[] buffer = new Byte[32];
	[Export]public int[] data = new int[10];
	
	public override void _Ready()
	{
		base._Ready();
		serialPort = new SerialPort(commPort, baudRate);
		/*
		serialPort.Parity = Parity.None;
		serialPort.StopBits = StopBits.One;
		serialPort.DataBits = 8;
		serialPort.Handshake = Handshake.None;
		*/
	}

	public bool OpenPort()
	{
		try
		{
			serialPort.Open();
			return true;
		}
		catch(Exception e)
		{
			GD.Print("failed to open port: ", e.Message);
			return false;
		}
	}

	public bool ReadSerial()
	{
		if(serialPort.IsOpen)
		{
			if(serialPort.BytesToRead > 0) // >=32?  > x?
			{
				// fill buffer
				// for each sensor
				// 	temp data
				// 	if valid
				//	  memcpy

				int byteCount = sizeof(Int16) * nBytesToRead;
				serialPort.Read(buffer, 0, byteCount);
				
				int arrIndex = 0;
				for(int i = 0; i < byteCount; i += sizeof(Int16))
				{
					data[arrIndex] = BitConverter.ToInt16(buffer, i);
					arrIndex++;
				}
				//GD.Print(data[0], "\t", data[1], "\t",data[2], "\t",data[3]);
				return true;
			}
		}
		return false;
	}

	public void ClosePort()
	{
		if (serialPort.IsOpen)
		{
			serialPort.Close();
			GD.Print("Serial port closed.");
		}
	}

}
