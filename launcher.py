#!/usr/bin/python3

import argparse
import os
import subprocess
import sys
import time
import random

from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, wait, as_completed

class Logger(object):
    def __init__(self, filename="./logs/default.log"):
        self.terminal = sys.stdout
        self.log = open(filename, "a")

    def write(self, message):
        log="[{0}] {1}".format(time.strftime('%Y-%m-%d %H:%M:%S'),message)
        self.terminal.write(message)
        self.log.write(log)

    def flush(self):
        pass

LOG_FILE = "./logs/ehealth.log"
root_dir="./network/"
datasets = ["std", "large", "xlarge"]
sys.stdout = Logger(LOG_FILE)
parser = argparse.ArgumentParser(description='Launch the benchmarks tests for CLARUS')
parser.add_argument('target', type=str,
                help='Define the target host')
parser.add_argument('directory',
                help='Define the directory containing the datasets')
parser.add_argument('requirement',
                help='Define the requirement id that will be tested')
parser.add_argument('-u', '--users', type=int, default=1,
                help='Define the number of virtual users within the pool')
parser.add_argument('-l', '--list', action="store_true",
                help='List the requirements supported')
parser.add_argument('-v', '--verbose', action="store_true",
                help='Increase the verbosity')
args = parser.parse_args()

def init_db(encrypt=False, dataset_size="std"):
    db_name="ehealth_{}".format(random.randint(1,100))
    script_path=os.path.join(root_dir, 'pgsqlBenchmarks.sh');
    script_args=" {} {} {} {} {}".format(args.target, args.directory, dataset_size, db_name, encrypt)
    cmd=script_path+script_args
    if args.verbose:
        print("Command: {}".format(cmd))
    try:
        output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
    except CalledProcessError:
        print("An exception occured")
        return False
    return db_name

def cleaning_db(db_name):
    script_path=os.path.join(root_dir, 'cleaning_pgsqlBenchmarks.sh');
    script_args=" {} {} {} {}".format(args.target, args.directory, "", db_name)
    cmd=script_path+script_args
    if args.verbose:
        print("Command: {}".format(cmd))
    try:
        output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
    except CalledProcessError:
        print("An exception occured")
        return False
    return True

def not_implemented():
    return nill

def worker_delivery_1():
    if subprocess.run("curl  --head http://clarussecure.eu/packages/latest/clarus_amd64.deb 2>/dev/null | head -n 1 | cut -d ' ' -f2") == "200":
        return True
    return False

def worker_delivery_4():
    if subprocess.run("curl  --head http://clarussecure.eu/doc/latest/CLARUS_INSTALLATION_GUIDE.pdf 2>/dev/null | head -n 1 | cut -d ' ' -f2") == "200":
        return True
    return False

def worker_delivery_5():
    if subprocess.run("curl  --head http://clarussecure.eu/doc/latest/CLARUS_CONFIGURATION_GUIDE.pdf 2>/dev/null | head -n 1 | cut -d ' ' -f2") == "200":
        return True
    return False

def worker_perf(encrypt=False, dataset_size="std"):
    db_name="ehealth_{}".format(random.randint(1,100))
    script_path=os.path.join(root_dir, 'pgsqlBenchmarks.sh');
    script_args=" {} {} {} {} {}".format(args.target, args.directory, dataset_size, db_name, encrypt)
    cmd=script_path+script_args
    if args.verbose:
        print("Command: {}".format(cmd))
    try:
        output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
    except CalledProcessError:
        print("An exception occured")
        return False
    time.sleep(5)

    script_path=os.path.join(root_dir, 'cleaning_pgsqlBenchmarks.sh');
    script_args=" {} {} {} {}".format(args.target, args.directory, dataset_size, db_name)
    cmd=script_path+script_args
    if args.verbose:
        print("Command: {}".format(cmd))
    try:
        output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
    except CalledProcessError:
        print("An exception occured")
        return False
    time.sleep(5)

    return True

def worker_perf_1():
    worker_perf()

    return True

def worker_perf_2():
    worker_perf(True, "std")
    worker_perf(True, "large")
    worker_perf(True, "xlarge")

    return True

def worker_perf_3():
    for dataset in datasets:
        my_db = init_db()
        script_path=os.path.join(root_dir, 'pgsqlBenchmarks_queries.sh');
        script_args=" {} {} {} {} {}".format(args.target, args.directory, dataset, my_db, False)
        cmd=script_path+script_args
        start_time=time.time()
        if args.verbose ==True:
            print(cmd)
        try:
             output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print("An exception occured: {}".format(e.output))
            return False
        time2compute=time.time()-start_time
        print("NO_SECURITY: {}s\tdataset size: {}".format(time2compute, dataset))
        cleaning_db(my_db)
        time.sleep(5)
        my_db = init_db(encrypt=True)
        script_path=os.path.join(root_dir, 'pgsqlBenchmarks_queries.sh');
        script_args=" {} {} {} {} {}".format(args.target, args.directory, dataset, my_db, True)
        cmd=script_path+script_args
        start_time=time.time()
        if args.verbose ==True:
            print(cmd)
        try:
             output = subprocess.run(cmd + " | gawk '{print strftime(\"[%Y-%m-%d %H:%M:%S]\"), $0; fflush();}' >> ./logs/ehealth.log", shell=True, check=True)
        except CalledProcessError:
            print("An exception occured")
            return False

        time2compute=time.time()-start_time
        print("SECURITY: {}s\tdataset size: {}".format(time2compute, dataset))
        cleaning_db(my_db)
        time.sleep(5)

    return True

def worker_perf_4():
    dataset_size="std"
    start_time=time.time()
    worker_perf(dataset_size=dataset_size)
    time2compute=time.time()-start_time
    print("{}\t: {}".format(dataset_size, time2compute))
    # Sleeping to allow postgres to cool down
    time.sleep(5)

    dataset_size="large"
    start_time=time.time()
    worker_perf(dataset_size=dataset_size)
    time2compute=time.time()-start_time
    print("{}\t: {}".format(dataset_size, time2compute))
    # Sleeping to allow postgres to cool down
    time.sleep(5)

    dataset_size="xlarge"
    start_time=time.time()
    worker_perf(dataset_size=dataset_size)
    time2compute=time.time()-start_time
    print("{}\t: {}".format(dataset_size, time2compute))

    return True

def worker_perf_5():
    # TODO
    return True

def worker_transport_3():
    # Calling JMETER here
    test_plan="test_plans/REQ-NF_TRSP-1.3.jmx"
    result_file="results/REQ-NF_TRSP-1.3.jtl"
    subprocess.run("jmeter -n -t {} -l {}".format(test_plan, result_file))
    print("Latency: {}".format(subprocess.run("cat {} | awk -F ',' '{print (2}')".format(result_file))))


def worker():
    print("Using worker {}".format(args.requirement))
    return requirement_func[args.requirement]()

requirement_func = {
        'REQ-NF_DLV-1.1': worker_delivery_1,
        'REQ-NF_DLV-1.4': worker_delivery_4,
        'REQ-NF_DLV-1.5': worker_delivery_5,
        'REQ-NF_PERF-1.1': worker_perf_1,
        'REQ-NF_PERF-1.2': worker_perf_2,
        'REQ-NF_PERF-1.3': worker_perf_3,
        'REQ-NF_PERF-1.4': worker_perf_4,
        'REQ-NF_PERF-1.5': worker_perf_5,
        'REQ-NF_TRSP-1.3': worker_transport_3
        }

def main():
    if args.list == True:
        for key, value in requirement_func.items():
            print(key); 
        return 0 
    futures = []
    start_time=time.time()
    with ThreadPoolExecutor(max_workers=args.users) as executor:
        for x in range(args.users):
            futures.append(executor.submit(worker))
    for x in as_completed(futures):
        print(x.result())
    time2compute=time.time()-start_time
    print("Time to compute: {}".format(time2compute))


if __name__ == '__main__':
    main()