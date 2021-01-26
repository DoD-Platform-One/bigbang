package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const kubeconfigPath string = "/etc/rancher/k3s/k3s.yaml"
const defaultService string = "k3s"
const defaultTimeout int = 30

func main() {
	localhosts := []string{"localhost", regexp.QuoteMeta("127.0.0.1")} // v0.8.1 and below use "localhost", newer versions use "127.0.0.1"
	hostRegexp := regexp.MustCompile(`\b` + strings.Join(localhosts, "|") + `\b`)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		service := r.URL.Query().Get("service")
		if service == "" {
			service = defaultService
		}
		timeout, _ := strconv.Atoi(r.URL.Query().Get("timeout"))
		if timeout <= 0 {
			timeout = defaultTimeout
		}
		var dat []byte
		var err error
		var i int
		for i = 0; i < timeout; i++ {
			dat, err = ioutil.ReadFile(kubeconfigPath)
			if err == nil && hostRegexp.Match(dat) {
				break
			}
			time.Sleep(1 * time.Second)
		}
		if i >= timeout {
			// A timeout happens if and only if err != nil
			err = fmt.Errorf("Timed out waiting a valid kubeconfig at %v. File read error: %v", kubeconfigPath, err)
			// It's ok to include the error because this is a developer tool (for use in CI)
			msg := fmt.Sprintf("500 - Internal server error: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(msg))
			return
		}
		kubeconfig := hostRegexp.ReplaceAll(dat, []byte(service))
		_, _ = w.Write(kubeconfig)
	})

	http.HandleFunc("/images", func(w http.ResponseWriter, r *http.Request) {
		cmd := exec.Command("crictl", "images", "-o", "json")
		var out bytes.Buffer
		cmd.Stdout = &out

		err := cmd.Run()
		if err != nil {
			err = fmt.Errorf("Failed to list containerd images: %v", err)
			msg := fmt.Sprintf("500 - Internal server error: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(msg))
			return
		}

		_, _ = w.Write(out.Bytes())
	})

	log.Fatal(http.ListenAndServe(":8081", nil))
}
