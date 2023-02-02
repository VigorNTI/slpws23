function remove(id, btn)
{
	e = btn.parentElement.getElementsByClassName("name")[0].children[0];
	e2= btn.parentElement.getElementsByClassName("supplier")[0].getElementsByTagName("p")[0];
	if (!confirm("Are you sure you want to remove " + e.innerHTML + " by " + e2.innerHTML + "?"))
	{
		return;
	}
	var url = "/products/" + id + "/delete";
	var params = "";
	var xhr = new XMLHttpRequest();
	xhr.open("POST", url, true);

	//Send the proper header information along with the request
	xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

	xhr.onreadystatechange = () => {
		if (xhr.readyState === 4)
		{
			if (xhr.response == "OK")
			{
				btn.parentElement.remove();
			}
		}
	}

	xhr.send(params);
}
