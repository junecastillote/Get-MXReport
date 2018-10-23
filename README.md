<p>
<img width="102" height="102" align="left" style="float: left; display: inline;" src="https://1.bp.blogspot.com/-i8eIjV0fXjk/WKR5wIG5-fI/AAAAAAAAAwk/1WyLIOqP-jIpngPFeViyIJtDst5gMPNdgCLcB/s1600/pshell.jpg">When you manage an email system, you’re sure to deal with MX records, and sometimes it is good to be able to generate a report of all the DNS MX Records for your domains to monitor their validity or availability. Being caught by surprise as your MX records go missing and your users start reporting their emails are not arriving is not good.</p>
<p>
This script can query a list of domains for their MX records, and generate a report which can be also sent as an email. Depending on your purpose, you can just run it manually or setup a task to run the script at an interval or daily schedule.</p>
<h3>
Requirements</h3>
<p>
This script requires PowerShell version 5.1</p>
<h3>
Download Link</h3>
<p>
<a title="https://github.com/junecastillote/Get-MXReport" href="https://github.com/junecastillote/Get-MXReport">https://github.com/junecastillote/Get-MXReport</a></p>
<h3>
How to Use</h3>
<p>
Modify the variables as show below to fit your requirements.</p>
<p>
<a href="https://lh3.googleusercontent.com/-rZgmqkfHV6s/W3e9E549mLI/AAAAAAAAC0k/8TYCW7BmAxs5pZ_fql8nKjYtgOpalbQngCHMYCw/s1600-h/mRemoteNG_2018-08-18_14-15-05%255B3%255D"><img width="671" height="321" title="" style="display: inline; background-image: none;" alt="" src="https://lh3.googleusercontent.com/-mfWkZiVUcIo/W3e9GnOHgVI/AAAAAAAAC0o/1bo6JDCiOewcImnB2mbZ2NsYVN3badEVwCHMYCw/mRemoteNG_2018-08-18_14-15-05_thumb%255B1%255D?imgmax=800" border="0"></a></p>
<p>
Open the file “domains.txt” and enter your list of domains that you want the script to query.</p>
<p>
<a href="https://lh3.googleusercontent.com/-4BaXUCTYMKY/W3e9H6LAt8I/AAAAAAAAC0s/Qf_6oZUcHt45nuQalSnRu4ZlRMnLlpx5wCHMYCw/s1600-h/mRemoteNG_2018-08-18_14-21-02%255B2%255D"><img width="169" height="110" title="" style="display: inline; background-image: none;" alt="" src="https://lh3.googleusercontent.com/-GiVWaHsM7X0/W3e9JeuCDYI/AAAAAAAAC0w/FSGdS2Tfk1ENBwDoqcx7X4_u5Y-CRMWAQCHMYCw/mRemoteNG_2018-08-18_14-21-02_thumb?imgmax=800" border="0"></a></p>
<p>
Then you can execute the script from PowerShell, no parameters required.</p>
<p>
<a href="https://lh3.googleusercontent.com/-MSssBPzwqxw/W3e9KrDRaOI/AAAAAAAAC00/8_kJ-EoDrWIYHpvTnTecRKzeXqCYEK4rwCHMYCw/s1600-h/mRemoteNG_2018-08-18_14-22-50%255B3%255D"><img width="478" height="173" title="" style="display: inline; background-image: none;" alt="" src="https://lh3.googleusercontent.com/-y0512yF3YbY/W3e9L__YK2I/AAAAAAAAC04/NsCMQUKtpA82j4ruoWnnYRpwtH_eqd27wCHMYCw/mRemoteNG_2018-08-18_14-22-50_thumb%255B1%255D?imgmax=800" border="0"></a></p>
<h3>
Sample Output</h3>
<h4>
Email Report</h4>
<p>
<a href="https://lh3.googleusercontent.com/-4UtG8W1BLWM/W3e9NlXuVHI/AAAAAAAAC08/Tj9UyKCxEwE4MABsTtdWe0eTvr8W74WswCHMYCw/s1600-h/mRemoteNG_2018-08-18_14-26-20%255B6%255D"><img width="769" height="490" title="mRemoteNG_2018-08-18_14-26-20" style="display: inline; background-image: none;" alt="mRemoteNG_2018-08-18_14-26-20" src="https://lh3.googleusercontent.com/-yr-bp5Tx_m0/W3e9O93XjYI/AAAAAAAAC1A/X9AXG3WrqrI-7DHVDekjoXNBC-6U8MiKgCHMYCw/mRemoteNG_2018-08-18_14-26-20_thumb%255B2%255D?imgmax=800" border="0"></a></p>
