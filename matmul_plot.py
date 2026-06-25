from matplotlib import pyplot as plt


data_static = []
data_dynamic = []
data_guided = []

list_of_thread_counts = [2,4,8]

matrix_size_index = 0

num_runs = 8




for num_threads in list_of_thread_counts:
    with open("matmul_execution_time/static_"+str(num_threads)+".txt") as f:
        data_static.append([])
        for line in f.readlines():
            entries = line.split(",")
            data_static[-1].append(float(entries[1]))
    with open("matmul_execution_time/dynamic_"+str(num_threads)+".txt") as f:
        data_dynamic.append([])
        for line in f.readlines():
            entries = line.split(",")
            data_dynamic[-1].append(float(entries[1]))
    with open("matmul_execution_time/guided_"+str(num_threads)+".txt") as f:
        data_guided.append([])
        for line in f.readlines():
            entries = line.split(",")
            data_guided[-1].append(float(entries[1]))
        

matrix_size_index = 5


plt.plot([data_static[i][matrix_size_index] for i in range(len(list_of_thread_counts))],label="static",color="blue")
#plt.plot([data_dynamic[i][matrix_size_index] for i in range(len(list_of_thread_counts))],label="dynamic",color="green")
#plt.plot([data_guided[i][matrix_size_index] for i in range(len(list_of_thread_counts))],label="guided",color="orange")

plt.xticks([i for i in range(len(list_of_thread_counts))],labels=list_of_thread_counts)
plt.xlabel("# Threads")
plt.ylabel("Execution time")
plt.show()



for t_index in range(len(list_of_thread_counts)):
    plt.plot(data_static[t_index], label=str(list_of_thread_counts[t_index]) + " Threads")


plt.title("Matrix Transposition")
plt.xlabel("Matrix size")
plt.ylabel("Execution Time")
plt.legend()
#plt.xticks([i for i in range(len(data[0]))],labels=[64,128,256,512,1024,2048,4096,8192])
plt.show()
    