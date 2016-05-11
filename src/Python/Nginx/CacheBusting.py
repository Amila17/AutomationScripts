import subprocess
import sys
import getopt
from shutil import rmtree
from os import mkdir


def delete_directory_content(path):
    try:
        rmtree(path, ignore_errors=True)
        mkdir(path)
    except:
        print("Exception is: ", sys.exc_info()[0])


def restart_service(service_name):
    try:
        print("systemctl restart " + service_name)
        subprocess.call("systemctl restart " + service_name, shell=True)
    except:
        print("Exception is: ", sys.exc_info()[0])
        raise


def main(argv):
    path = ''
    service_name = ''

    try:
        opts, args = getopt.getopt(argv, "p:s:", ["path=", "serviceName="])
    except getopt.GetoptError:
        print("Wrong parameters passed in.")
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-p", "--path"):
            path = arg
        elif opt in ("-s", "--serviceName"):
            service_name = arg
        else:
            print("Wrong parameters passed in.")
            sys.exit(2)

    try:
        print("Path argument is: ", path)
        print("Service Name argument is: ", service_name)

        print("Calling Delete Directory Content")
        delete_directory_content(path)

        print("Calling Restart Service")
        restart_service(service_name)

        print("Execution is complete.")

    except:
        print("Exception is: ", sys.exc_info()[0])
        raise


if __name__ == "__main__":
    main(sys.argv[1:])
