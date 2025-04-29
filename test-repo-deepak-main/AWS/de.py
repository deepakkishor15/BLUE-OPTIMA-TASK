import boto3
import pandas as pd
import numpy as np

# Initialize the EC2 client
ec2_client = boto3.client('ec2', region_name='us-east-1')

# CSV file containing the tag updates
csv_file = '/home/control/tag_update.csv'  # Ensure this is the correct path

# Load the CSV file into a DataFrame
df = pd.read_csv(csv_file)

# Print out the data frame to check if it's loaded correctly
print("CSV Data Loaded:")
print(df)

# Iterate through each row in the DataFrame
for index, row in df.iterrows():
    instance_id = row['Hostname']  # Assuming 'Hostname' is the EC2 instance ID column
    old_department = row['Current Department']
    new_department = row['New Department']

    if pd.isna(old_department):  # Skip rows where 'Current Department' is NaN
        print(f"Skipping {instance_id} because it has no current department value.")
        continue

    print(f"Processing instance {instance_id} with current department: {old_department} and new department: {new_department}")

    try:
        # Get instances by tag filter
        response = ec2_client.describe_instances(
            Filters=[
                {'Name': 'tag:Hostname', 'Values': [instance_id]},
                {'Name': 'tag:Department', 'Values': [old_department]}
            ]
        )

        instances = response.get('Reservations', [])

        if instances:
            for reservation in instances:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    print(f"Found instance {instance_id}. Updating department tag...")

                    # Update the 'Department' tag with the new value
                    ec2_client.create_tags(
                        Resources=[instance_id],
                        Tags=[{'Key': 'Department', 'Value': new_department}]
                    )
                    print(f"Updated instance {instance_id} with new Department: {new_department}")
        else:
            print(f"No matching instance found for {instance_id} with Department {old_department}")

    except Exception as e:
        print(f"Error updating instance {instance_id}: {e}")

(myenv) control@control:~$
