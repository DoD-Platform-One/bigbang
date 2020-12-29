import boto3
import operator
import ipaddress
initial_cidr = "10.10.0.0/16"
client = boto3.client('ec2', region_name='us-gov-west-1')
res = client.describe_vpcs(Filters=[{}])
vpcIds = list(map(operator.itemgetter("CidrBlock"), res["Vpcs"]))
vpcIds.sort()
unique_cidr = False
while not unique_cidr:
    found_cidr_overlap = False
    for cidr in vpcIds:
        aws_cidr = ipaddress.IPv4Network(cidr)
        try:
            proposed_cidr = ipaddress.IPv4Network(initial_cidr)
        except:
            logger.error("Couldn't convert cidr of " + str(initial_cidr))
            sys.exit(2)

        if aws_cidr.overlaps(proposed_cidr):
            found_cidr_overlap = True
            break
    allowed_private_cidr = ipaddress.IPv4Network("10.0.0.0/8")
    if not found_cidr_overlap:
        if allowed_private_cidr.overlaps(proposed_cidr):
            unique_cidr = True
            final_vpc = initial_cidr
        else:
            logger.error("Proposed cidr not in private ip space: " + str(initial_cidr))
            sys.exit(2)
    else:
        try:
            initial_cidr = str(ipaddress.ip_address(initial_cidr.split("/")[0]) + 65536) + "/16"
        except:
            logger.error("Couldn't update cidr of " + str(initial_cidr))
            sys.exit(2)
print(final_vpc)
