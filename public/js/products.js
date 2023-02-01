function remove(id, btn)
{
	s = btn.parentElement.getElementsByClassName("info")[0];
	e = s.children[0];
	e2 = s.children[1];
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
