# Developer Guidance

<b style="color:red">We have a Github workflow to create AMIs. The following is deprecated.</b>

To deploy an updated AMI instance from local, do the following:

```
cd app/fastapi_test/deploy/packer
packer init .
packer build -var-file=staging.pkrvars.hcl .
```


If the build is successful, you should see commandline logs that end with the following:
```
==> fastapi-test.amazon-ebs.fastapi_test: Successfully installed Jinja2-3.1.6 MarkupSafe-3.0.2 PyYAML-6.0.2 Pygments-2.19.1 annotated-types-0.7.0 anyio-4.9.0 certifi-2025.4.26 click-8.1.8 dnspython-2.7.0 email_validator-2.2.0 exceptiongroup-1.3.0 fastapi-0.115.12 fastapi-cli-0.0.7 h11-0.16.0 httpcore-1.0.9 httptools-0.6.4 httpx-0.28.1 idna-3.10 markdown-it-py-3.0.0 mdurl-0.1.2 pydantic-2.11.5 pydantic_core-2.33.2 python-dotenv-1.1.0 python-multipart-0.0.20 rich-14.0.0 rich-toolkit-0.14.6 shellingham-1.5.4 sniffio-1.3.1 starlette-0.46.2 typer-0.16.0 typing-inspection-0.4.1 typing_extensions-4.13.2 uvicorn-0.34.2 uvloop-0.21.0 watchfiles-1.0.5 websockets-15.0.1
==> fastapi-test.amazon-ebs.fastapi_test: Created symlink /etc/systemd/system/multi-user.target.wants/fastapi_test.service → /etc/systemd/system/fastapi_test.service.
==> fastapi-test.amazon-ebs.fastapi_test: Stopping the source instance...
==> fastapi-test.amazon-ebs.fastapi_test: Stopping instance
==> fastapi-test.amazon-ebs.fastapi_test: Waiting for the instance to stop...
==> fastapi-test.amazon-ebs.fastapi_test: Creating AMI fastapi-test-staging-0.0-20250607011709 from instance i-0a90d5f63aafdbf86
==> fastapi-test.amazon-ebs.fastapi_test: Attaching run tags to AMI...
==> fastapi-test.amazon-ebs.fastapi_test: AMI: ami-0759062ce9ee67faa
==> fastapi-test.amazon-ebs.fastapi_test: Waiting for AMI to become ready...
==> fastapi-test.amazon-ebs.fastapi_test: Skipping Enable AMI deprecation...
==> fastapi-test.amazon-ebs.fastapi_test: Skipping Enable AMI deregistration protection...
==> fastapi-test.amazon-ebs.fastapi_test: Terminating the source AWS instance...
==> fastapi-test.amazon-ebs.fastapi_test: Cleaning up any extra volumes...
==> fastapi-test.amazon-ebs.fastapi_test: No volumes to clean up, skipping
==> fastapi-test.amazon-ebs.fastapi_test: Deleting temporary security group...
==> fastapi-test.amazon-ebs.fastapi_test: Deleting temporary keypair...
Build 'fastapi-test.amazon-ebs.fastapi_test' finished after 8 minutes 45 seconds.

==> Wait completed after 8 minutes 45 seconds

==> Builds finished. The artifacts of successful builds are:
--> fastapi-test.amazon-ebs.fastapi_test: AMIs were created:
us-west-2: ami-0759062ce9ee67faa
```