function remove(id, btn)
{
	td = btn.parentElement
	tr = td.parentElement
	name = document.querySelector("#id"+id+" input[name='name']")

	if (!confirm("Are you sure you want to remove " + name.value + "?"))
	{
		return;
	}
	var url = "/users/" + id + "/delete";
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

function update(id, btn)
{
	tr = btn.parentElement.parentElement
	name = document.querySelector("#id"+id+" input[name='name']").value
	admin_level = document.querySelector("#id"+id+" input[name='admin_level']").value

	var url = "/users/" + id + "/update";
	var params = "id="+id+"&name="+name+"&admin_level="+admin_level;
	var xhr = new XMLHttpRequest();
	xhr.open("POST", url, true);

	//Send the proper header information along with the request
	xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

	xhr.onreadystatechange = () => {
		if (xhr.readyState === 4)
		{
			if (xhr.response == "DEL")
			{
				tr.remove();
			}
			else if (xhr.response == "OK")
			{
				alert("User data has been saved")
			}
			else
			{
				alert(xhr.response)
			}
		}
	}

	xhr.send(params);
}
