# Mattermost  

Mattermost is the primary collaboration tool used in the DSOP pipeline. More information on the application can be found [here.](https://mattermost.org/)  

## Application Pre-requisites

* kubectl

## Getting Started

To deploy Mattermost, clone the repository and run:

``
git clone https://repo1.dsop.io/platform-one/apps/mattermost.git
``

``
cd app/monitoring/prometheus
``

```
kubectl apply -k .
```
## The image repo has been changed to Iron Bamk

You will need to patch the mattermost-operator to support your Iron Bank secrets.

Put your Iron bank secrets under apps/common/dev.  You will need generators for both registry and repo secrets.

Patch the matermost operator:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mattermost-operator
# Adding common secrets for harbor images
imagePullSecrets:
  - name: your-repo-creds
  - name: your-registry-read-creds
  ```

## Metrics in Mattermost

### Prometheus Metrics

The list of metrics collected by prometheus for mattermost:

(<https://docs.mattermost.com/deployment/metrics.html>)

NOTE: Current implementation provides only standard GO metrics

To enable prometheus metrics in Mattermost:
``
cd app/monitoring/prometheus
``
``
kubectl apply -k .
``

## Logging  

### Pre-requisites

mattermost is deployed

ECK/Fluentd is deployed

### Kibana

1. Login to Kibana
    username: elastic
    Password :
</br> Password can be obtained by querying 
`kubectl get secret elasticsearch-es-elastic-user -n elastic -o yaml  `
</br>
2. Create Index by  selecting Management icon from the left menu and  clicking Index patterns under Kibana. </br>
In the Create Index patterns <mattermost*> and click create index pattern.  

    In the the next step Click on the dropdown and select "@timestamp"
    </br>
3. For Search click on Discovery from the side menu.  
</br>

4. In KQL textbox enter the  field of interest for eg:  "kubernets.namespace.name : mattermost*"  
</br>

5. Click Refresh/Update

NOTE: Default indexpattern is "mattermost*" and this may change in future. Check the available index name  

## Applicaiton specific logging  

1. Create a mattermost user (if SSO isn't configured)

The sysadmin has to be created.  The following steps will create a user and prompte the user to sys-admin.  

``kubectl get pods -n mattermost``  

2. Pick one of the chat pods.  

``chat-68755f7ffb-``*xxxx*``1/1     Running   0          3h12m``  

3. Create a user.  The e-mail address needs to be one of the approved domains.  

``fbi.gov, dc3.mil, mail.mil, us.af.mil, afwerx.af.mil, diu.mil, usmc.mil, us.army.mil, us.navy.mil, navy.mil, kr.af.mil, niwc.navy.mil, spawar.navy.mil, afit.edu, sco.mil, nsa.gov, darpa.mil, pacom.mil, socom.mil, mitre.org, aero.org, mda.mil, nrl.navy.mil, auab.afcent.af.mil, adab.afcent.af.mil, dau.edu, AZAB.AFCENT.AF.MIL, afcent.af.mil, deployed.af.mil, sd.mil, whmo.mil, hpc.mil, dren.mil, jhuapl.edu, diux.mil, jsf.mi``

To create a user:  
``kubectl exec chat-68755f7ffb-xxxx -n mattermost -- mattermost user create --email randomadmin@us.af.mil --username randomguy --password P@ssw0rdclear``  

Remember to change the password when logging into ``https://chat.fenses.dsop.io`` .  

4. Promote the user to system admin:  

``kubectl exec chat-68755f7ffb-xxxx -n mattermost -- mattermost roles system_admin randomguy``

Using the userid from the admin user, verify events in the kibana mattermost query.  User IC can be found under User Management -> Users 

In kibana, query  "log : userId" to track all user activities.
