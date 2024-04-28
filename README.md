## Required Software
* **Web Server**
    * [ColdFusion Developer Edition](https://www.adobe.com/products/coldfusion/download-trial/try.html)
    * [XAMPP (Apache, PHP, MySQL, phpMyAdmin)](https://www.apachefriends.org/index.html)

* **Development**
    * [Sublime Text 3](https://www.sublimetext.com/3)

* **Source Control**
    * [Git](https://git-scm.com/downloads)
    * [Source Tree](https://www.sourcetreeapp.com/)

## Installation

1. First install the source control software. Install Git and make sure to check the option that adds it to the PATH environment variable. After Git has installed, install Source Tree.

2. Install Sublime Text 3. It will be a trial version with **no** limited time.

3. Now install XAMPP. It will ask you which modules you would like to install, just check them all and continue.

4. Once XAMPP is installed, open it up and try to start the Apache and MySQL service. If you encounter errors ask for help.

5. Now that XAMPP is installed and Apache is running (**make sure you keep Apache running**) you can install ColdFusion. Click through the wizard until you get to the web server connector section. It should give you the option to add a connector. If so, select Apache and point the configuration directory to `C:\xampp\apache\conf`. Then point the binary path to `C:\xampp\apache\bin\httpd.exe`. Ignore any ambiguous errors and continue through the wizard until ColdFusion has been installed.

6. Download [this jar file](https://github.com/smallstone-uk/setup/raw/master/mysql-connector-java-5.1.40-bin.jar) and place it in both `C:\ColdFusion2016\cfusion\lib` and `C:\ColdFusion2016\cfusion\wwwroot\WEB-INF\lib`.

7. Open `C:\xampp\apache\conf\mod_jk.conf` and comment the line that starts with `JkShmFile` by putting a `#` at the start of the line. Like the following: `# JkShmFile "C:\ColdFusion2016\config\wsconfig\1\jk_shm"`

8. Download [setup.bat](https://raw.githubusercontent.com/smallstone-uk/setup/master/setup.bat) to your computer. Open command prompt and `cd` to the location of `setup.bat`, eg. `cd /D C:\Users\James\Documents`. Next run the setup script with your desired project location. The project location is the location where you will write code from, usually in your documents. Run the script by doing the following (**make sure you wrap the project path in quotes**): `setup "C:\Users\James\Documents"`. The script will then clone the repositories and set them up to use with Apache.

9. If the setup script completed without errors then you should have multiple hosts created for the repo's. It will create hosts in the format `dev.{repo-name}.lan` and `{repo-name}.lan`. Try visiting [http://dev.sle-admin.lan](http://dev.sle-admin.lan) in your web browser.

10. The next step is to download the databases from the production server. Do this by downloading the [MySQL tool](https://github.com/small-stone-group/setup/raw/master/mysql-gui-tools-5.0-r14-win32.msi) and connecting to the production server's MySQL. Create a backup of everything to your desktop. Then disconnect from the production server, and connect to your local MySQL server and restore that backup.

11. You will now need to create the corresponding ColdFusion datasources for the given project. Open the ColdFusion administrator by going to [http://localhost/CFIDE/administrator](http://localhost/CFIDE/administrator).

12. Now the website should all be setup. If it isn't then perhaps I'm missing something here.
