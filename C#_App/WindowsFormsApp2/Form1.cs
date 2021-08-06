using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WindowsFormsApp2
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            Process myProcess = new Process();
            myProcess.StartInfo.FileName = "C:\\Users\\Salma Ibrahim\\Desktop\\hello.exe";
            myProcess.StartInfo.UseShellExecute = false;
            myProcess.StartInfo.RedirectStandardInput = true;
            myProcess.StartInfo.RedirectStandardOutput = true;
            myProcess.Start();
            StreamWriter myStreamWriter = myProcess.StandardInput;
            StreamReader reader = myProcess.StandardOutput;
            myStreamWriter.WriteLine(richTextBox1.Text);
            //while (true) { 
            //string output = reader.ReadLine();}
            string x = Console.ReadLine();
            //Console.WriteLine(x);
            richTextBox2.Text = File.ReadAllText("C:\\Users\\Salma Ibrahim\\Desktop\\out.txt");
            //Console.WriteLine(myProcess.StandardOutput.ReadToEnd());
            myStreamWriter.Close();
            myProcess.WaitForExit();
        }
    }
}
