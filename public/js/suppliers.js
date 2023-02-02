function remove(id, btn)
{
	td = btn.parentElement
	tr = td.parentElement
	td1= tr.children[0]
	a  = td1.children[0]

	if (!confirm("Are you sure you want to remove " + a.innerHTML + "?"))
	{
		return;
	}
	var url = "/suppliers/" + id + "/delete";
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
				tr.remove();
			}
		}
	}

	xhr.send(params);
}
