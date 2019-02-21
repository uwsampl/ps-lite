#include "ps/ps.h"
#include "ps/internal/postoffice.h"
#include <math.h>
#include <vector>
#include <chrono>

using namespace ps;
int num = 1;
int chunk = 16;
void StartServer()
{
  if (!IsServer())
  {
    return;
  }
  auto server = new KVServer<float>(0);
  server->set_request_handle(KVServerDefaultHandleSingleArray<float>());
  RegisterExitCallback([server]() { delete server; });
}

void RunWorker()
{
  if (!IsWorker())
    return;
  KVWorker<float> kv(0, 0);

  int keySize = chunk;
  std::vector<Key> keys(num);
  std::vector<float> vals(keySize);
  std::vector<int> lens(1, keySize);

  int rank = MyRank();
  srand(rank + 7);
  for (int i = 0; i < num; ++i)
  {
    keys[i] = kMaxKey / num * i + rank;
    //vals[i] = (rand() % 1000);
  }

  // push

  int repeat = 50;
  std::vector<int> ts;
  std::vector<uint64_t> times;

  std::vector<int> recvTs;

  std::vector<int> retLens;
  std::vector<float> retVals;
  for (int i = 0; i < repeat; ++i)
  {
    LOG(INFO) << "[" << i << "] iteration = " << i;
    ts.clear();
    recvTs.clear();
    uint64_t ms = std::chrono::duration_cast<std::chrono::microseconds>(
                      std::chrono::system_clock::now().time_since_epoch())
                      .count();
    for (int k = 0; k < num; k++)
    {
      ts.push_back(kv.Push(std::vector<ps::Key>(1, keys[k]), vals, lens));
    }
    for (int t : ts)
      kv.Wait(t);

    // pull
    for (int k = 0; k < num; k++)
    {
      recvTs.push_back(kv.Pull(std::vector<Key>(1, keys[k]), &retVals));
    }

    for (int t : recvTs)
      kv.Wait(t);

    uint64_t end = std::chrono::duration_cast<std::chrono::microseconds>(
                       std::chrono::system_clock::now().time_since_epoch())
                       .count();
    times.push_back(end - ms);
  }

  std::sort(times.begin(), times.end());
  printf("median: %d(us)\r\n", times[times.size() / 2]);
  fflush(stdout);
}

int main(int argc, char *argv[])
{
  std::string str = "400";
    if (argc > 1) { str = argv[1];
      num = atoi(str.c_str());
    }
    std::string chunkStr = "65536";
    if (argc > 2) { chunkStr = argv[2];
      chunk = atoi(chunkStr.c_str());
    }
  // start system
  Start(0);
  // setup server nodes
  StartServer();
  //force a barrier for init?
  ps::Postoffice::Get()->Barrier(0, 7);
  // run worker nodes
  RunWorker();
  // stop system
  Finalize(0, true);
  return 0;
}
